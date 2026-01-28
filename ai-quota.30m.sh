#!/bin/bash
# <xbar.title>AI Quota Monitor</xbar.title>
# <xbar.version>4.0</xbar.version>
# <xbar.author>Weli</xbar.author>

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SKILL_DIR="/Users/marioinostroza/clawd/skills/clawdbot-official/skills"
AG_SCRIPT="$SKILL_DIR/mukhtharcm/antigravity-quota/check-quota.js"

WORST=100
LINES=""

if [ -f "$AG_SCRIPT" ]; then
  RAW=$(node "$AG_SCRIPT" 2>/dev/null)

  while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
    
    if echo "$trimmed" | grep -qE '^[a-z].*: [0-9].*%'; then
      MODEL=$(echo "$trimmed" | cut -d: -f1)
      # The percentage IS the remaining quota
      REMAINING_F=$(echo "$trimmed" | grep -oE '[0-9]+\.[0-9]+' | head -1)
      REMAINING=${REMAINING_F%.*}
      RESET=$(echo "$trimmed" | sed 's/.*resets //' | sed 's/)//')

      if [ "$REMAINING" -lt "$WORST" ]; then WORST=$REMAINING; fi

      # Friendly name
      case "$MODEL" in
        claude-opus*thinking)     NAME="Claude Opus" ;;
        claude-sonnet*thinking)   NAME="Sonnet (T)" ;;
        claude-sonnet*)           NAME="Sonnet" ;;
        gemini-3-flash*)          NAME="Gemini Flash" ;;
        gemini-3-pro*)            NAME="Gemini Pro" ;;
        *)                        NAME="$MODEL" ;;
      esac

      # Bar (5 blocks)
      FILLED=$((REMAINING / 20))
      EMPTY=$((5 - FILLED))
      BAR=""
      for ((i=0; i<FILLED; i++)); do BAR+="█"; done
      for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

      # Color
      if [ "$REMAINING" -ge 80 ]; then CLR="green"
      elif [ "$REMAINING" -ge 50 ]; then CLR="#FFD700"
      elif [ "$REMAINING" -ge 20 ]; then CLR="orange"
      else CLR="red"; fi

      LINES+="$BAR  ${REMAINING}%  $NAME | font=Menlo size=13 color=$CLR\n"
      LINES+="     ↻ $RESET | font=Menlo size=11 color=#666666\n"
    fi
  done <<< "$RAW"
fi

# --- Menu Bar ---
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
else
  echo "⚠️  Sin datos | color=#888888"
fi

echo "---"
echo "🔄 Actualizar | refresh=true"
echo "📋 Abrir Notion | href=https://www.notion.so/Centro-de-Mando-IA-Suscripciones-Usos-2f517c8f978b81f58f82c4d8df686d33"
