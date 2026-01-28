#!/bin/bash
# <xbar.title>AI Quota Monitor</xbar.title>
# <xbar.version>9.0</xbar.version>
# <xbar.author>Weli</xbar.author>

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SKILL_DIR="/Users/marioinostroza/clawd/skills/clawdbot-official/skills"
AG_SCRIPT="$SKILL_DIR/mukhtharcm/antigravity-quota/check-quota.js"
CX_SCRIPT="$SKILL_DIR/odrobnik/codex-quota/codex-quota.py"

WORST=100
LINES=""

# --- 1. Antigravity Models ---
if [ -f "$AG_SCRIPT" ]; then
  RAW=$(node "$AG_SCRIPT" 2>/dev/null)
  while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
    if echo "$trimmed" | grep -qE '^[a-z0-9_].*: [0-9].*%'; then
      MODEL=$(echo "$trimmed" | cut -d: -f1)
      REM_F=$(echo "$trimmed" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | sed 's/%//')
      REM=${REM_F%.*}
      RESET=$(echo "$trimmed" | sed 's/.*resets //' | sed 's/)//')

      if [ "$REM" -lt "$WORST" ]; then WORST=$REM; fi

      case "$MODEL" in
        claude-opus*)       NAME="Claude Opus" ;;
        claude-sonnet*)     NAME="Claude Sonnet" ;;
        gemini-3-flash*)    NAME="Gemini Flash" ;;
        gemini-3-pro*)      NAME="Gemini Pro" ;;
        gpt-oss-120b*)      NAME="OpenCode (AG)" ;;
        chat_20706)         NAME="GPT-4o (AG)" ;;
        chat_23310)         NAME="GPT-4o-mini (AG)" ;;
        *)                  NAME="$MODEL" ;;
      esac

      FILLED=$((REM / 20))
      EMPTY=$((5 - FILLED))
      BAR=""
      for ((i=0; i<FILLED; i++)); do BAR+="█"; done
      for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

      if [ "$REM" -ge 80 ]; then CLR="green"
      elif [ "$REM" -ge 50 ]; then CLR="#FFD700"
      elif [ "$REM" -ge 20 ]; then CLR="orange"
      else CLR="red"; fi

      LINES+="$BAR  ${REM}%  $NAME | font=Menlo size=12 color=$CLR\n"
      LINES+="     ↻ $RESET | font=Menlo size=10 color=#666666\n"
    fi
  done <<< "$RAW"
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
    
    if [ "$REM_P" -ge 80 ]; then CX_CLR="green"
    elif [ "$REM_P" -ge 50 ]; then CX_CLR="#FFD700"
    elif [ "$REM_P" -ge 20 ]; then CX_CLR="orange"
    else CX_CLR="red"; fi
    
    CX_LINES="🧠  Codex / OpenCode | font=Menlo size=12 color=white\n"
    CX_LINES+="█████  ${REM_P}%  Cuota Semanal | font=Menlo size=12 color=$CX_CLR\n"
    CX_LINES+="     💰 \$${BAL} balance disponible | font=Menlo size=10 color=#666666\n"
    CX_LINES+="     • gpt-5.1-codex-max | size=11 color=#bbbbbb\n"
    CX_LINES+="     • gpt-5.1-codex-mini | size=11 color=#bbbbbb\n"
    CX_LINES+="     • gpt-5.2-codex | size=11 color=#bbbbbb\n"
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
