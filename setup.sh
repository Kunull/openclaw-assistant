#!/usr/bin/env bash
# setup.sh — install and configure jomon/openclaw-assistant
# Installs: Node 24, Ollama, OpenClaw, pulls required models,
# copies config templates, and wires up the knowledge organizer.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
REQUIRED_NODE="24"
OPENCLAW_PKG="openclaw@latest"
CHAT_MODEL="qwen2.5:3b"
EMBED_MODEL="qwen3-embedding:0.6b"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[setup]${NC} $*"; }
success() { echo -e "${GREEN}[setup]${NC} $*"; }
warn()    { echo -e "${YELLOW}[setup]${NC} $*"; }
die()     { echo -e "${RED}[setup] ERROR:${NC} $*" >&2; exit 1; }

# ── 1. Node.js ────────────────────────────────────────────────────────────────
info "Checking Node.js..."

if command -v nvm &>/dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.nvm/nvm.sh"
  CURRENT_MAJOR=$(node --version 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo "0")
  if [ "$CURRENT_MAJOR" -lt "$REQUIRED_NODE" ]; then
    info "Upgrading Node to v${REQUIRED_NODE} via nvm..."
    nvm install "$REQUIRED_NODE"
    nvm use "$REQUIRED_NODE"
  fi
elif command -v brew &>/dev/null; then
  CURRENT_MAJOR=$(node --version 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo "0")
  if [ "$CURRENT_MAJOR" -lt "$REQUIRED_NODE" ]; then
    info "Installing Node via Homebrew..."
    brew install node@"$REQUIRED_NODE"
    brew link --overwrite node@"$REQUIRED_NODE"
  fi
else
  die "Neither nvm nor Homebrew found. Install Node $REQUIRED_NODE manually: https://nodejs.org"
fi

NODE_VER=$(node --version)
success "Node $NODE_VER ready"

# ── 2. Ollama ────────────────────────────────────────────────────────────────
info "Checking Ollama..."

if ! command -v ollama &>/dev/null; then
  if command -v brew &>/dev/null; then
    info "Installing Ollama via Homebrew..."
    brew install ollama
    brew services start ollama
  elif command -v apt-get &>/dev/null; then
    info "Installing Ollama via apt..."
    curl -fsSL https://ollama.com/install.sh | sh
  else
    die "Cannot auto-install Ollama. Install it manually: https://ollama.com/download"
  fi
else
  # Make sure the service is running
  if command -v brew &>/dev/null && ! brew services list | grep -q "ollama.*started"; then
    brew services start ollama
  fi
fi

success "Ollama $(ollama --version 2>/dev/null | head -1) ready"

# ── 3. Pull models ────────────────────────────────────────────────────────────
info "Pulling $CHAT_MODEL (chat model)..."
ollama pull "$CHAT_MODEL"
success "$CHAT_MODEL pulled"

info "Pulling $EMBED_MODEL (embedding model for semantic search)..."
ollama pull "$EMBED_MODEL"
success "$EMBED_MODEL pulled"

# ── 4. OpenClaw ───────────────────────────────────────────────────────────────
info "Installing OpenClaw..."
npm install -g "$OPENCLAW_PKG"
# Approve bundled install scripts
npm approve-scripts --allow-scripts-pending 2>/dev/null || true
success "OpenClaw $(openclaw --version 2>/dev/null) installed"

# ── 5. Config files ───────────────────────────────────────────────────────────
info "Installing config files..."
mkdir -p "$OPENCLAW_DIR"

# Ask for Telegram chat ID (optional — can be set later)
echo ""
echo -e "${YELLOW}To route approval requests to Telegram, enter your chat ID.${NC}"
echo -e "Get it by messaging ${CYAN}@userinfobot${NC} on Telegram."
echo -e "Press Enter to skip and set it manually later in ~/.openclaw/openclaw.json"
echo ""
read -rp "Telegram chat ID (or Enter to skip): " TELEGRAM_ID

copy_config() {
  local src="$1" dst="$2"
  if [ -f "$dst" ]; then
    warn "Backing up existing $dst → ${dst}.bak"
    cp "$dst" "${dst}.bak"
  fi
  cp "$src" "$dst"
}

copy_config "$REPO_DIR/config/openclaw.json" "$OPENCLAW_DIR/openclaw.json"
copy_config "$REPO_DIR/config/exec-approvals.json" "$OPENCLAW_DIR/exec-approvals.json"

if [ -n "$TELEGRAM_ID" ]; then
  # Substitute the placeholder in openclaw.json
  sed -i.bak "s/YOUR_CHAT_ID/$TELEGRAM_ID/g" "$OPENCLAW_DIR/openclaw.json"
  rm -f "$OPENCLAW_DIR/openclaw.json.bak"
  success "Telegram chat ID set to $TELEGRAM_ID"
else
  warn "Skipped. Edit ~/.openclaw/openclaw.json and replace YOUR_CHAT_ID when ready."
fi

success "Config files installed"

# ── 6. Project dependencies ───────────────────────────────────────────────────
info "Installing project dependencies..."
cd "$REPO_DIR"
npm install
success "Dependencies installed"

# ── 7. OpenClaw onboarding ────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup complete! One manual step remaining:${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Run the OpenClaw onboarding wizard to connect a channel:"
echo -e ""
echo -e "  ${CYAN}openclaw onboard --install-daemon${NC}"
echo -e ""
echo -e "When prompted:"
echo -e "  • Model  → ollama  →  ${CHAT_MODEL}"
echo -e "  • Channel → telegram (or whatsapp)"
echo -e "  • Install daemon → yes"
echo ""
echo -e "Then start the knowledge organizer (keeps running in background):"
echo -e ""
echo -e "  ${CYAN}npm run organize${NC}  (from $REPO_DIR)"
echo ""
echo -e "Daily notes will appear in:"
echo -e "  ${CYAN}$REPO_DIR/knowledge/YYYY/MM/YYYY-MM-DD.md${NC}"
echo ""
