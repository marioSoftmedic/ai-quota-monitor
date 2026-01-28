# 🤖 AI Quota Monitor for xbar

A clean macOS menu bar widget to monitor your AI service quotas at a glance. Built for developers juggling multiple LLM subscriptions.

![Status](https://img.shields.io/badge/platform-macOS-blue) ![License](https://img.shields.io/badge/license-MIT-green)

## What it does

Shows a simple traffic light in your menu bar:

- 🟢 **Green** — 80%+ quota remaining, work freely
- 🟡 **Yellow** — 50-79% remaining, moderate heavy usage
- 🟠 **Orange** — 20-49% remaining, prioritize important tasks
- 🔴 **Red** — <20% remaining, wait for reset

Click to see the full breakdown with progress bars per model.

## Screenshot

```
🔴 AI
─────────────────────────
🎮 Centro de Mando IA
─────────────────────────
░░░░░  0%    Claude Opus
     ↻ Jan 28, 2:56 PM
░░░░░  0%    Sonnet (T)
     ↻ Jan 28, 2:56 PM
█████  100%  Gemini Pro
     ↻ 4:56 AM
─────────────────────────
🔄 Actualizar
📋 Abrir Notion
```

## Supported Services

| Service | How it reads quota |
|---------|-------------------|
| **Google Antigravity** | Via `antigravity-quota` skill. Supports Claude, Gemini, and GPT-4o models. |
| **OpenAI Codex (Direct)** | Via `codex-quota` skill. Reads local session logs for balance ($) and weekly usage. |
| **GLM 4.7** | Manual status for active subscriptions. |
| **Claude Code** | Via `claude-code-usage` skill (queries Anthropic OAuth API). |

## Requirements

- **macOS** (Apple Silicon or Intel)
- **[xbar](https://xbarapp.com/)** — Menu bar plugin framework
- **Node.js** (for Antigravity quota check)
- **Python 3** (for Codex quota check)
- One or more of the quota check scripts (see Supported Services)

## Installation

### 1. Install xbar

```bash
brew install --cask xbar
```

### 2. Copy the plugin

```bash
cp ai-quota.30m.sh ~/Library/Application\ Support/xbar/plugins/
chmod +x ~/Library/Application\ Support/xbar/plugins/ai-quota.30m.sh
```

### 3. Configure paths

Edit the `SKILL_DIR` variable in the script to point to your quota check scripts:

```bash
SKILL_DIR="/path/to/your/quota/scripts"
```

### 4. Launch xbar

```bash
open -a xbar
```

The widget refreshes every **30 minutes** automatically. Click **🔄 Actualizar** for instant refresh.

## How Antigravity Quotas Work

Antigravity provides access to multiple AI models with separate quota pools:

| Pool | Models | Reset Cycle |
|------|--------|-------------|
| 🟣 **Claude** | Opus, Sonnet (shared pool) | Every 5 hours |
| 🔵 **Gemini Pro** | gemini-3-pro-high | Every 5 hours |
| ⚡ **Gemini Flash** | gemini-3-flash | Every 5 hours |

Each pool resets **independently**. The menu bar icon reflects your **lowest** quota across all pools.

## Customization

### Change refresh interval

Rename the file to change the interval:
- `ai-quota.30m.sh` → every 30 minutes
- `ai-quota.5m.sh` → every 5 minutes
- `ai-quota.1h.sh` → every hour

### Add a Notion link

The plugin includes a quick link to open your Notion dashboard. Edit the `href` URL at the bottom of the script.

## Built With

- [xbar](https://xbarapp.com/) — macOS menu bar plugin framework
- [antigravity-quota](https://github.com/mukhtharcm) — Antigravity API quota checker
- [codex-quota](https://github.com/odrobnik) — OpenAI Codex session log parser
- [claude-code-usage](https://github.com/azaidi94) — Claude Code OAuth usage checker
- [Clawdbot](https://github.com/clawdbot/clawdbot) — AI assistant framework

## Author

**Mario Inostroza** — [@marioinostroza](https://x.com/marioinostroza)

Built with the help of [Weli](https://github.com/clawdbot/clawdbot) 👵🏼, an AI assistant powered by Clawdbot.

## License

MIT — Use it, fork it, improve it. If you find it useful, a ⭐ on the repo is appreciated!
