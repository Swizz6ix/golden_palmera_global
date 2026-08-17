#!/usr/bin/env bash

set -Eeuo pipefail

case "${INPUT_STATUS}" in
    success)
        ICON="✅"
        ;;
        
    failure)
        ICON="❌"
        ;;
        
    cancelled)
        ICON="⚪"
        ;;
        
    *)
        ICON="ℹ️"
        ;;
esac

TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
SHORT_SHA="${INPUT_SHA:0:7}"

RUN_URL="https://github.com/${INPUT_REPOSITORY}/actions/runs/${INPUT_RUN_ID}"

# Telegram HTML escaping 
escape_html() {
    local value="$1"
    
    value="${value//&/&amp;}"
    value="${value//</&lt;}"
    value="${value//>/&gt;}"
    
    printf '%s' "$value"
} 

TITLE=$(escape_html "${INPUT_TITLE}")
ENVIRONMENT=$(escape_html "${INPUT_ENVIRONMENT}")
STATUS=$(escape_html "${INPUT_STATUS}")
REPOSITORY=$(escape_html "${INPUT_REPOSITORY}")
WORKFLOW=$(escape_html "${INPUT_WORKFLOW}")
BRANCH=$(escape_html "${INPUT_BRANCH}")
ACTOR=$(escape_html "${INPUT_ACTOR}")
MESSAGE=$(escape_html "${INPUT_MESSAGE}")

TEXT=$(cat <<EOF
${ICON} <b>${TITLE}</b>

<b>Environment:</b> ${ENVIRONMENT} 
<b>Status:</b> ${STATUS}

<b>Repository:</b> ${REPOSITORY}
<b>Workflow:</b> ${WORKFLOW}
<b>Branch:</b> ${BRANCH}
<b>Commit:</b> <code>${SHORT_SHA}</code>
<b>Actor:</b> ${ACTOR}
<b>Run:</b> #${INPUT_RUN_NUMBER}
<b>Time:</b> ${TIME}

${MESSAGE}

<a href="${RUN_URL}">View GitHub Actions Run</a>
EOF
)

curl \
    --silent \
    --show-error \
    --fail \
    --retry 3 \
    --retry-delay 5 \
    --retry-all-errors \
    --request POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${TEXT}" \
    --data-urlencode "parse_mode=HTML"
