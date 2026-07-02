/**
 * Watches OpenClaw's memory directory for new daily note files (YYYY-MM-DD.md),
 * moves them into knowledge/YYYY/MM/YYYY-MM-DD.md, and injects YAML frontmatter
 * with auto-generated topic tags via the local Ollama API.
 */

import { watch } from 'chokidar'
import { readFile, writeFile, mkdir, rename } from 'fs/promises'
import { existsSync } from 'fs'
import { join, basename } from 'path'
import { homedir } from 'os'

const MEMORY_DIR = join(homedir(), '.openclaw', 'workspace', 'memory')
const KNOWLEDGE_DIR = join(homedir(), 'projects', 'jomon', 'assistant', 'knowledge')
const OLLAMA_URL = 'http://localhost:11434/api/generate'
const MODEL = 'qwen2.5:3b'

const DAILY_NOTE_RE = /^(\d{4})-(\d{2})-(\d{2})(?:-[^.]+)?\.md$/

async function generateTags(content) {
  const prompt = `Read the following notes and return a JSON array of 3-8 short topic tags (lowercase, hyphenated if multi-word) that best describe the subjects discussed. Return ONLY the JSON array, nothing else.

Notes:
${content.slice(0, 3000)}

Tags:`

  const res = await fetch(OLLAMA_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: MODEL, prompt, stream: false }),
  })

  if (!res.ok) throw new Error(`Ollama error: ${res.status}`)
  const { response } = await res.json()

  // Extract the JSON array from the model response
  const match = response.match(/\[.*?\]/s)
  if (!match) return []
  return JSON.parse(match[0])
}

function buildFrontmatter(date, tags) {
  const lines = [
    '---',
    `date: ${date}`,
    `tags: [${tags.map(t => `"${t}"`).join(', ')}]`,
    '---',
    '',
  ]
  return lines.join('\n')
}

function stripExistingFrontmatter(content) {
  if (!content.startsWith('---')) return content
  const end = content.indexOf('---', 3)
  if (end === -1) return content
  return content.slice(end + 3).trimStart()
}

async function processFile(srcPath) {
  const filename = basename(srcPath)
  const match = filename.match(DAILY_NOTE_RE)
  if (!match) return

  const [, year, month, day] = match
  const date = `${year}-${month}-${day}`

  const destDir = join(KNOWLEDGE_DIR, year, month)
  const destPath = join(destDir, `${date}.md`)

  // Skip if already organized
  if (existsSync(destPath)) return

  console.log(`[organizer] Processing ${filename}`)

  const raw = await readFile(srcPath, 'utf8')
  const body = stripExistingFrontmatter(raw)

  let tags = []
  try {
    tags = await generateTags(body)
    console.log(`[organizer] Tags for ${date}:`, tags)
  } catch (err) {
    console.warn(`[organizer] Tag generation failed: ${err.message}`)
  }

  const output = buildFrontmatter(date, tags) + body

  await mkdir(destDir, { recursive: true })
  await writeFile(destPath, output, 'utf8')
  console.log(`[organizer] Written → knowledge/${year}/${month}/${date}.md`)
}

// Watch for new or updated daily note files in the memory directory
const watcher = watch(join(MEMORY_DIR, '*.md'), {
  persistent: true,
  ignoreInitial: false,
  awaitWriteFinish: { stabilityThreshold: 1500, pollInterval: 200 },
})

watcher
  .on('add', processFile)
  .on('change', processFile)
  .on('error', err => console.error('[organizer] Watcher error:', err))

console.log(`[organizer] Watching ${MEMORY_DIR}`)
console.log(`[organizer] Organizing into ${KNOWLEDGE_DIR}`)
