#!/bin/bash
# <xbar.title>AI Quota Monitor V2</xbar.title>
# <xbar.version>15.0</xbar.version>
# <xbar.author>Cotocha (Weli Assistant)</xbar.author>
# <xbar.desc>Monitor robusto de cuotas LLM con parsing real y tracking de estado.</xbar.desc>

# --- Configuración de Paths ---
# Ajusta estos paths a tu entorno local
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Directorio de sesiones (Clawdbot logs)
SESSIONS_DIR="$HOME/.clawdbot/agents/main/sessions"
CACHE_DIR="$HOME/.cache/ai-quota-monitor"
mkdir -p "$CACHE_DIR"

STATE_FILE="$CACHE_DIR/last_offsets.json"
DAILY_STATS="$CACHE_DIR/daily_stats_$(date +%Y-%m-%d).json"

# --- Precios por 1M de Tokens (USD) ---
# Puedes editarlos según cambien los precios de OpenAI/Gemini/Zai
PRICE_OPENAI=2.50
PRICE_GOOGLE=1.00
PRICE_ZAI=0.50

# --- Lógica de Parsing V2 (Robusta) ---

# Inicializar archivos de estado
[ ! -f "$STATE_FILE" ] && echo "{}" > "$STATE_FILE"
[ ! -f "$DAILY_STATS" ] && echo '{"openai":0, "google":0, "zai":0, "total":0, "tokens":0}' > "$DAILY_STATS"

process_sessions() {
    # Solo procesar archivos modificados en las últimas 24h
    find "$SESSIONS_DIR" -name "*.jsonl" -mtime -1 2>/dev/null | while read -r session_path; do
        session_id=$(basename "$session_path")
        last_offset=$(jq -r ".[\"$session_id\"] // 0" "$STATE_FILE")
        current_size=$(stat -f%z "$session_path" 2>/dev/null || stat -c%s "$session_path" 2>/dev/null)
        
        if [ "$current_size" -gt "$last_offset" ]; then
            # Leer solo lo nuevo
            tail -c +$((last_offset + 1)) "$session_path" | while read -r line; do
                [ -z "$line" ] && continue
                
                # Extraer usage con jq (Soporta múltiples formatos de Clawdbot)
                usage=$(echo "$line" | jq -c '.message.usage // .usage // empty' 2>/dev/null)
                if [ -n "$usage" ]; then
                    tokens=$(echo "$usage" | jq -r '.totalTokens // .total_tokens // 0')
                    provider_raw=$(echo "$line" | jq -r '.message.provider // .provider // "unknown"')
                    
                    cost=0
                    prov_key="unknown"
                    if [[ "$provider_raw" == *"openai"* ]]; then
                        prov_key="openai"
                        cost=$(echo "scale=6; $tokens * $PRICE_OPENAI / 1000000" | bc -l)
                    elif [[ "$provider_raw" == *"google"* || "$provider_raw" == *"antigravity"* ]]; then
                        prov_key="google"
                        cost=$(echo "scale=6; $tokens * $PRICE_GOOGLE / 1000000" | bc -l)
                    elif [[ "$provider_raw" == *"zai"* ]]; then
                        prov_key="zai"
                        cost=$(echo "scale=6; $tokens * $PRICE_ZAI / 1000000" | bc -l)
                    fi
                    
                    if [ "$prov_key" != "unknown" ]; then
                        tmp_stats="$DAILY_STATS.tmp"
                        jq ".tokens += $tokens | .[\"$prov_key\"] += $cost | .total += $cost" "$DAILY_STATS" > "$tmp_stats" && mv "$tmp_stats" "$DAILY_STATS"
                    fi
                fi
            done
            # Guardar nuevo offset
            tmp_state="$STATE_FILE.tmp"
            jq ".[\"$session_id\"] = $current_size" "$STATE_FILE" > "$tmp_state" && mv "$tmp_state" "$STATE_FILE"
        fi
    done
}

# Ejecutar proceso (silencioso)
process_sessions >/dev/null 2>&1

# --- Recopilación de Datos para Display ---
STATS=$(cat "$DAILY_STATS")
TOTAL_USD=$(echo "$STATS" | jq -r '.total')
TOTAL_TOKENS=$(echo "$STATS" | jq -r '.tokens')
OA_USD=$(echo "$STATS" | jq -r '.openai')
G_USD=$(echo "$STATS" | jq -r '.google')
Z_USD=$(echo "$STATS" | jq -r '.zai')

# Determinar icono de salud (basado en presupuesto diario de $25 total aprox)
HEALTH_ICON="🟢"
[ $(echo "$TOTAL_USD > 10" | bc -l) -eq 1 ] && HEALTH_ICON="🟡"
[ $(echo "$TOTAL_USD > 18" | bc -l) -eq 1 ] && HEALTH_ICON="🟠"
[ $(echo "$TOTAL_USD > 22" | bc -l) -eq 1 ] && HEALTH_ICON="🔴"

# --- Output Final (xbar format) ---
echo "$HEALTH_ICON \$${TOTAL_USD:0:4} | size=13"
echo "---"
echo "🎮 Centro de Mando IA V2 | size=14"
echo "---"

# Progress Bar Helper (Python)
render_bar() {
    local val=$1
    local limit=$2
    local label=$3
    local color=$4
    python3 -c "
pct = min(int(($val/$limit)*100), 100)
f = pct // 20
bar = '█' * f + '░' * (5 - f)
print(f'{bar}  {pct}%  $label | font=Menlo size=12 color=$color')
"
}

echo "Hoy: $TOTAL_TOKENS tokens usados"
echo "Costo Total: \$$TOTAL_USD USD"
echo "---"

# Detalle por Provider
render_bar "$OA_USD" 15 "OpenAI ($OA_USD)" "cyan"
render_bar "$G_USD" 8 "Google ($G_USD)" "orange"
render_bar "$Z_USD" 8 "ZAI/GLM ($Z_USD)" "purple"

echo "---"
echo "📂 Logs: $SESSIONS_DIR | size=10"
echo "🔄 Actualizar | refresh=true"
echo "📋 Abrir Notion | href=https://www.notion.so/Centro-de-Mando-IA-Suscripciones-Usos-2f517c8f978b81f58f82c4d8df686d33"
