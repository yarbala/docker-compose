#!/usr/bin/env bash
set -euo pipefail

# Example: ./unlock-path.sh domain.some.yarbala.com /api/webhooks/whatsapp [nginx-proxy]

DOMAIN="${1:-}"; PATH_EXACT="${2:-}"; CONTAINER="${3:-nginx-proxy}"

if [[ -z "$DOMAIN" || -z "$PATH_EXACT" ]]; then
  echo "Usage: $0 <domain> <path> [container_name]" >&2
  exit 1
fi

BANNER="# --- UNLOCK ${DOMAIN} ${PATH_EXACT} ---"
TMPFILE="$(mktemp)"

# 1) вытащить upstream (proxy_pass) из активного конфига прокси
UPSTREAM="$(docker exec -i "$CONTAINER" sh -lc \
"awk '
  /server_name[[:space:]]+$DOMAIN[[:space:]]*;/ {s=1}
  s && /location[[:space:]]+\\// {l=1}
  s && l && /proxy_pass/ {print \$2; exit}
' /etc/nginx/conf.d/default.conf | sed 's/;//'")"

# запасной вариант, если не нашли
if [[ -z "$UPSTREAM" ]]; then
  UPSTREAM="http://$DOMAIN"
fi

# 2) готовим сниппет. Пишем в vhost.d/default (он точно include'ится в твоём конфиге)
cat >"$TMPFILE" <<EOF

$BANNER
location = ${PATH_EXACT} {
    auth_basic off;
    auth_request off;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass ${UPSTREAM};
}
location = ${PATH_EXACT%/}/ {
    auth_basic off;
    auth_request off;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass ${UPSTREAM};
}
$BANNER
EOF

# 3) установить сниппет: убрать старый блок (если был), затем добавить новый
docker exec -i "$CONTAINER" sh -lc "
set -e
SNIP=/etc/nginx/vhost.d/default
if [ -f \"\$SNIP\" ]; then
  awk '
    BEGIN{skip=0}
    /^# --- UNLOCK ${DOMAIN//\//\\/} ${PATH_EXACT//\//\\/} ---\$/ {skip=1; next}
    skip && /^# --- UNLOCK/ {skip=0}
    !skip {print}
  ' \"\$SNIP\" > \"\$SNIP.new\" && mv \"\$SNIP.new\" \"\$SNIP\"
fi
cat >>\"\$SNIP\" <<'EOSNIP'
$(cat "$TMPFILE")
EOSNIP
nginx -t && nginx -s reload
"

rm -f "$TMPFILE"

echo "✓ Unlocked BasicAuth for https://${DOMAIN}${PATH_EXACT}"
echo "Upstream: ${UPSTREAM}"
echo
echo "Quick check (VERIFY-like):"
echo "  curl -v \"https://${DOMAIN}${PATH_EXACT}?hub.mode=subscribe&hub.verify_token=test&hub.challenge=42\""
