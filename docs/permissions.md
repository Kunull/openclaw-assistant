# Permission tiers

OpenClaw uses a two-tier model. Tier 1 commands run silently. Tier 2 commands send an interactive approval card to your Telegram (or WhatsApp) before executing.

## How it works

- `config/openclaw.json` defines which tools are always allowed and configures the approval routing channel.
- `config/exec-approvals.json` defines the shell command allowlist with optional argument pattern restrictions.
- Anything not matched by the allowlist triggers `ask: "on-miss"`, which routes to Telegram.

## Tier 1 — auto-approved, no prompt

### Tools (`tools.allow` in `openclaw.json`)

| Tool | What it does |
|---|---|
| `memory_search` | Semantic search over the knowledge base |
| `memory_get` | Read a specific memory file |
| `memory_write` | Write a new memory entry |
| `web_search` | Search the web |
| `web_fetch` | Fetch a URL |
| `fs_read` | Read any file |
| `fs_list` | List directory contents |

### Shell commands (`exec-approvals.json` allowlist)

| Command | Allowed arguments |
|---|---|
| `git` | `log`, `status`, `diff`, `show`, `branch`, `remote`, `fetch`, `ls-files`, `describe`, `tag --list` |
| `ls` | unrestricted |
| `cat` | unrestricted |
| `find` | unrestricted |
| `grep` | unrestricted |
| `wc` | unrestricted |
| `stat` | unrestricted |
| `ollama` | unrestricted |
| `npm` | `run organize` only |
| `node` | paths under `scripts/` or `~/projects/jomon/` only |
| `ps`, `top`, `df`, `du` | unrestricted |
| `uname`, `which`, `env`, `echo`, `date`, `pwd` | unrestricted |
| `curl` | GET requests only — blocked if `-X POST/PUT/DELETE/PATCH`, `--data`, or `--upload-file` are present |

## Tier 2 — requires Telegram approval

Any command or tool call not matched by Tier 1. Examples:

| Action | Why it needs approval |
|---|---|
| `git push` / `git reset` / `git checkout` | Mutates remote or local history |
| `rm`, `mv` | Destructive or irreversible |
| `npm install`, `pip install`, `brew install` | Modifies system or project dependencies |
| `curl -X POST/PUT/DELETE` | Writes to external APIs |
| `sudo <anything>` | Elevated privileges |
| `fs_write` outside workspace | Writes files outside the project |
| Plugin mutations | Sending messages, writing calendar events, etc. |

## Approving a request

When the agent needs permission it sends a card to your Telegram chat. You can reply with:

```
/approve <id> yes
/approve <id> no
```

Or use the inline buttons if your Telegram bot supports them.

## Changing the tiers

**To add a command to Tier 1** (auto-approve), add an entry to the `allowlist` array in `config/exec-approvals.json`:

```json
{
  "id": "my-command",
  "pattern": "mycommand",
  "argPattern": "^safe-subcommand"
}
```

`argPattern` is optional. Omit it to allow all arguments.

**To change the approval channel**, update `approvals.exec.targets` and `approvals.plugin.targets` in `config/openclaw.json`:

```json
"targets": [
  { "channel": "telegram", "to": "YOUR_CHAT_ID" }
]
```

Replace `telegram` with `whatsapp` to route approvals there instead.

## Setting your Telegram chat ID

1. Open Telegram and message **@userinfobot**
2. It replies with your numeric chat ID
3. Replace both occurrences of `YOUR_CHAT_ID` in `~/.openclaw/openclaw.json`

Or re-run `./setup.sh` — it prompts for the ID and substitutes it automatically.
