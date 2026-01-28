#!/bin/bash
# <xbar.title>AI Quota Monitor</xbar.title>
# <xbar.version>10.5</xbar.version>
# <xbar.author>Weli</xbar.author>

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SKILL_DIR="/Users/marioinostroza/clawd/skills/clawdbot-official/skills"
AG_SCRIPT="$SKILL_DIR/mukhtharcm/antigravity-quota/check-quota.js"
CX_SCRIPT="$SKILL_DIR/odrobnik/codex-quota/codex-quota.py"

WORST=100
LINES=""

# --- 1. Antigravity Models ---
if [ -f "$AG_SCRIPT" ]; then
  # Use Python for robust parsing of the raw output
  AG_PARSED=$(node "$AG_SCRIPT" 2>/dev/null | python3 -c "
import sys, re
models = []
for line in sys.stdin:
    m = re.search(r'^\s*([a-z0-9_-]+):\s*([0-9.]+).*% \(resets (.*)\)', line)
    if m:
        name_raw, rem, reset = m.groups()
        rem = float(rem)
        name = name_raw
        if 'claude-opus' in name_raw: name = 'Claude Opus'
        elif 'claude-sonnet' in name_raw: name = 'Claude Sonnet'
        elif 'gemini-3-flash' in name_raw: name = 'Gemini Flash'
        elif 'gemini-3-pro' in name_raw: name = 'Gemini Pro'
        elif 'chat_20706' in name_raw: name = 'GPT-4o (AG)'
        elif 'chat_23310' in name_raw: name = 'GPT-4o-mini (AG)'
        elif 'gpt-oss-120b' in name_raw: name = 'OpenCode (AG)'
        
        models.append({'name': name, 'rem': rem, 'reset': reset})

# Deduplicate by name (keeping lowest quota for that name group)
dedup = {}
for m in models:
    if m['name'] not in dedup or m['rem'] < dedup[m['name']]['rem']:
        dedup[m['name']] = m

for m in sorted(dedup.values(), key=lambda x: x['rem']):
    filled = int(m['rem'] / 20)
    bar = '█' * filled + '░' * (5 - filled)
    clr = 'red' if m['rem'] < 20 else ('orange' if m['rem'] < 50 else ('#FFD700' if m['rem'] < 80 else 'green'))
    print(f\"{bar}  {int(m['rem'])}%  {m['name']} | font=Menlo size=12 color={clr}\")
    print(f\"     ↻ {m['reset']} | font=Menlo size=10 color=#666666\")
")
  LINES="$AG_PARSED"
  
  # Calculate worst for the icon
  LOWEST=$(node "$AG_SCRIPT" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+%' | sed 's/\..*//' | sort -n | head -1)
  WORST=${LOWEST:-100}
fi

# --- 2. OpenAI Codex ---
CX_LINES=""
if [ -f "$CX_SCRIPT" ]; then
  CX_JSON=$(python3 "$CX_SCRIPT" --json 2>/dev/null)
  if [ -n "$CX_JSON" ] && ! echo "$CX_JSON" | grep -q "error"; then
    BAL=$(echo "$CX_JSON" | python3 -c "import json, sys; d=json.load(sys.stdin); print(round(float(d.get('credits', {}).get('balance', 0)), 2))")
    USED_P=$(echo "$CX_JSON" | python3 -c "import json, sys; d=json.load(sys.stdin); print(int(d['secondary']['used_percent']))")
    REM_P=$((100 - USED_P))
    if [ "$REM_P" -lt "$WORST" ]; then WORST=$REM_P; fi
    [ "$REM_P" -ge 80 ] && C="green" || ([ "$REM_P" -ge 50 ] && C="#FFD700" || ([ "$REM_P" -ge 20 ] && C="orange" || C="red"))
    CX_LINES="🧠  Codex / OpenCode | font=Menlo size=12 color=white\n"
    CX_LINES+="█████  ${REM_P}%  Cuota Semanal | font=Menlo size=12 color=$C\n"
    CX_LINES+="     💰 \$${BAL} balance disponible | font=Menlo size=10 color=#666666\n"
  fi
fi

# --- Menu Bar Icon ---
if [ "$WORST" -ge 80 ]; then ICON="🟢"
elif [ "$WORST" -ge 50 ]; then ICON="🟡"
elif [ "$WORST" -ge 20 ]; then ICON="🟠"
else ICON="🔴"; fi

echo "$ICON AI | size=13"
echo "---"
echo "🎮 Centro de Mando IA | size=14"
echo "---"

if [ -n "$LINES" ]; then
  echo -e "$LINES"
fi

if [ -n "$CX_LINES" ]; then
  echo -e "---"
  echo -e "$CX_LINES"
fi

echo "---"
echo "🟢 GLM 4.7 (Suscripción) · Activa | font=Menlo size=12 color=cyan"
echo "---"
echo "🔄 Actualizar | refresh=true"
echo "📋 Abrir Notion | href=https://www.notion.so/Centro-de-Mando-IA-Suscripciones-Usos-2f517c8f978b81f58f82c4d8df686d33"
