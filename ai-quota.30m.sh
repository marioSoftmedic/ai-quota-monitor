#!/bin/bash
# <xbar.title>AI Quota Monitor</xbar.title>
# <xbar.version>12.0</xbar.version>
# <xbar.author>Weli</xbar.author>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

SKILL_DIR="/Users/marioinostroza/clawd/skills/clawdbot-official/skills"
AG_SCRIPT="$SKILL_DIR/mukhtharcm/antigravity-quota/check-quota.js"
CX_SCRIPT="$SKILL_DIR/odrobnik/codex-quota/codex-quota.py"

# --- 1. Data Collection ---
AG_DATA=$(node "$AG_SCRIPT" 2>/dev/null)
CX_JSON=$(python3 "$CX_SCRIPT" --json 2>/dev/null)

# --- 2. Logic & Icons ---
# Extract percentages safely
LOWEST_AG=$(echo "$AG_DATA" | grep -oE '[0-9]+\.[0-9]+%' | sed 's/\..*//' | sort -n | head -1)
LOWEST_AG=${LOWEST_AG:-100}

CX_REM=100
if [ -n "$CX_JSON" ] && [[ "$CX_JSON" == *"secondary"* ]]; then
    CX_REM=$(echo "$CX_JSON" | python3 -c "import json, sys; d=json.load(sys.stdin); print(int(100 - d['secondary']['used_percent']))" 2>/dev/null || echo 100)
fi

# Determine global worst for menu bar icon
FINAL_REM=$LOWEST_AG
[ $CX_REM -lt $FINAL_REM ] && FINAL_REM=$CX_REM

[ $FINAL_REM -lt 20 ] && ICON="🔴" || ([ $FINAL_REM -lt 50 ] && ICON="🟠" || ([ $FINAL_REM -lt 80 ] && ICON="🟡" || ICON="🟢"))

# --- 3. Output ---
echo "$ICON AI | size=13"
echo "---"
echo "🎮 Centro de Mando IA | size=14"
echo "---"

# Parse AG Models with Python
if [ -n "$AG_DATA" ]; then
    echo "$AG_DATA" | python3 -c "
import sys, re
models = {}
for line in sys.stdin:
    m = re.search(r'^\s*([a-z0-9_-]+):\s*([0-9.]+).*% \(resets (.*)\)', line)
    if m:
        id, rem, reset = m.groups()
        rem = float(rem)
        name = id
        if 'claude-opus' in id: name = 'Claude Opus'
        elif 'claude-sonnet' in id: name = 'Claude Sonnet'
        elif 'gemini-3-flash' in id: name = 'Gemini Flash'
        elif 'gemini-3-pro' in id: name = 'Gemini Pro'
        elif 'chat_20706' in id: name = 'GPT-4o (AG)'
        elif 'chat_23310' in id: name = 'GPT-4o-mini (AG)'
        elif 'gpt-oss-120b' in id: name = 'OpenCode (AG)'
        else: continue
        if name not in models or rem < models[name]['rem']:
            models[name] = {'rem': rem, 'reset': reset}
for name in sorted(models.keys()):
    m = models[name]
    pct = int(m['rem'])
    f = pct // 20
    bar = '█' * f + '░' * (5 - f)
    clr = 'red' if pct < 20 else ('orange' if pct < 50 else ('#FFD700' if pct < 80 else 'green'))
    print(f'{bar}  {pct}%  {name} | font=Menlo size=12 color={clr}')
    print(f'     ↻ {m[\"reset\"]} | font=Menlo size=10 color=#666666')
"
fi

# Render Codex
if [ -n "$CX_JSON" ] && [[ "$CX_JSON" == *"balance"* ]]; then
    echo "---"
    echo "🧠 Codex / OpenCode (Direct CLI) | font=Menlo size=12 color=white"
    BAL=$(echo "$CX_JSON" | python3 -c "import json, sys; d=json.load(sys.stdin); print(round(float(d.get('credits', {}).get('balance', 0)), 2))" 2>/dev/null || echo "0.00")
    COLOR="red"; [ $CX_REM -ge 20 ] && COLOR="orange"; [ $CX_REM -ge 50 ] && COLOR="#FFD700"; [ $CX_REM -ge 80 ] && COLOR="green"
    BAR_FILLED=$((CX_REM / 20)); BAR=""
    for ((i=0; i<BAR_FILLED; i++)); do BAR+="█"; done
    for ((i=0; i<(5-BAR_FILLED); i++)); do BAR+="░"; done
    echo "$BAR  ${CX_REM}%  Cuota Semanal | font=Menlo size=12 color=$COLOR"
    echo "     💰 \$$BAL balance disponible | font=Menlo size=10 color=#666666"
fi

echo "---"
echo "🟢 GLM 4.7 (Suscripción) · Activa | font=Menlo size=12 color=cyan"
echo "---"
echo "🔄 Actualizar | refresh=true"
echo "📋 Abrir Notion | href=https://www.notion.so/Centro-de-Mando-IA-Suscripciones-Usos-2f517c8f978b81f58f82c4d8df686d33"
