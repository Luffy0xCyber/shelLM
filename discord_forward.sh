#!/usr/bin/env bash
WEBHOOK_URL="API_URL"
USER="kaiser"
IP_LAST_LOGIN=""

format_and_send () {
  local line="$1"
  local ip=$(echo "$line" | cut -d'|' -f1 | xargs)
  local ts=$(echo "$line" | cut -d'|' -f2 | xargs)
  local user=$(echo "$line" | cut -d'|' -f3 | xargs)
  local status=$(echo "$line" | cut -d'|' -f4 | xargs)

  local emoji=""
  case "$status" in
    "AUTH-OK") emoji="✅" ;;
    "AUTH-FAIL") emoji="❌" ;;
    "DISCONNECT") emoji="🔌" ;;
    *) emoji="🔔" ;;
  esac

  local message="**$emoji $status**
**User:** \`$user\`
**IP:** \`$ip\`
**Time:** \`$ts\`"

  local payload=$(jq -nc --arg content "$message" '{content: $content}')
  curl -s -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" >/dev/null
}

tail -n0 -F /var/log/shelLM/sessions.log /var/log/auth.log | while read -r raw; do
  ### 1) Détecter un évènement d'authentification
  if [[ "$raw" =~ sshd.*(Failed|Accepted)\ password\ for\ $USER\ from\ ([0-9.]+) ]]; then
      status=${BASH_REMATCH[1]}
      ip=${BASH_REMATCH[2]}
      IP_LAST_LOGIN=$ip
      ts=$(date '+%Y-%m-%d %H:%M:%S.%6N')
      [[ "$status" == "Accepted" ]] && tag="AUTH-OK" || tag="AUTH-FAIL"
      format_and_send "$ip | $ts | $USER | $tag"
      continue
  fi

  ### 2) Détecter une déconnexion SSH
  if [[ "$raw" =~ Disconnected\ from\ user\ $USER\ ([0-9.]+) ]]; then
      ip=${BASH_REMATCH[1]}
      ts=$(date '+%Y-%m-%d %H:%M:%S.%6N')
      format_and_send "$ip | $ts | $USER | DISCONNECT"
      continue
  fi

  ### 3) Ligne provenant de sessions.log -> déjà bien formattée
  if [[ "$raw" == *"| $USER |"* ]]; then
      format_and_send "$IP_LAST_LOGIN | $raw"
  fi
done
