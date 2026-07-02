# Knowledge base

The assistant builds a persistent, searchable knowledge base from every conversation. Notes are organized by date, tagged by topic, and indexed for semantic search — all stored locally.

## Folder structure

```
knowledge/
└── YYYY/
    └── MM/
        └── YYYY-MM-DD.md
```

Example:

```
knowledge/
└── 2026/
    └── 07/
        ├── 2026-07-01.md
        └── 2026-07-02.md
```

Each file has YAML frontmatter with the date and auto-generated topic tags:

```markdown
---
date: 2026-07-02
tags: ["local-ai", "openclaw", "setup", "ollama", "permissions"]
---

... session notes ...
```

## How it works

1. OpenClaw writes session summaries to `~/.openclaw/workspace/memory/YYYY-MM-DD.md` after each conversation.
2. `scripts/organize-knowledge.js` watches that directory for new or updated files.
3. When a file appears, the organizer:
   - Moves it to `knowledge/YYYY/MM/YYYY-MM-DD.md`
   - Calls `qwen2.5:3b` via the Ollama API to extract 3–8 topic tags from the content
   - Injects the tags as YAML frontmatter
4. The memory-wiki plugin indexes everything under `knowledge/` for search.

## Semantic search

The assistant uses `qwen3-embedding:0.6b` (local Ollama model) for embeddings. Search combines:

| Mode | Weight | Good for |
|---|---|---|
| Vector (semantic) | 70% | Conceptually related queries ("what did we discuss about security?") |
| Keyword (exact) | 30% | Specific terms, IDs, code symbols |

Additional features enabled:
- **MMR (Maximal Marginal Relevance)** — diversifies results so you don't get five near-identical notes
- **Temporal decay** — more recent notes rank slightly higher

## Nightly dreaming

`memory-core` runs a consolidation sweep at **3am** every night. It promotes frequently-referenced snippets into long-term memory and writes summaries to `memory/.dreams/`. This keeps the knowledge base clean without manual curation.

## Config reference

All memory settings live in `config/openclaw.json`:

| Key | Value | Effect |
|---|---|---|
| `agents.defaults.memorySearch.provider` | `local-ollama` | Uses Ollama for embeddings |
| `agents.defaults.memorySearch.model` | `qwen3-embedding:0.6b` | Embedding model |
| `agents.defaults.memorySearch.extraPaths` | `~/projects/jomon/assistant/knowledge` | Also indexes organized notes |
| `plugins.entries.memory-wiki.config.vault.path` | `~/projects/jomon/assistant/knowledge` | Wiki vault location |
| `plugins.entries.memory-wiki.config.bridge.indexDailyNotes` | `true` | Picks up daily YYYY-MM-DD.md files |
| `plugins.entries.memory-core.config.dreaming.frequency` | `0 3 * * *` | 3am nightly sweep |

## Running the organizer

```bash
npm run organize
```

Keep this running in a terminal or add it to your shell's startup. It exits cleanly on `Ctrl+C`.
