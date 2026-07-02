# jomon / openclaw-assistant

A local-first personal assistant built on [OpenClaw](https://github.com/openclaw/openclaw) and [Ollama](https://ollama.com). All inference runs on-device — no data leaves your machine.

## Quick start

```bash
git clone https://github.com/Kunull/openclaw-assistant.git
cd openclaw-assistant
./setup.sh
```

After `setup.sh` completes, run the OpenClaw onboarding wizard:

```bash
openclaw onboard --install-daemon
```

When prompted: model → `ollama` → `qwen2.5:3b`, channel → `telegram` (or `whatsapp`), install daemon → `yes`.

Then start the knowledge organizer in the background:

```bash
npm run organize
```

## What's included

| File | Purpose |
|---|---|
| `setup.sh` | One-command installer — Node 24, Ollama, models, OpenClaw, config |
| `config/openclaw.json` | Main OpenClaw config template |
| `config/exec-approvals.json` | Command allowlist for the two-tier permission model |
| `scripts/organize-knowledge.js` | Watches memory output, files notes into `knowledge/YYYY/MM/`, injects tags |
| `docs/permissions.md` | Full permission tier reference |
| `docs/knowledge-base.md` | Knowledge base structure and config reference |

## Docs

- [Permission tiers](docs/permissions.md) — what runs silently vs. what asks for Telegram approval
- [Knowledge base](docs/knowledge-base.md) — daily notes, folder structure, tagging, semantic search
