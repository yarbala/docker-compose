# nginx-proxy-prod: basic auth and per-vhost configuration

The production proxy image (base `nginxproxy/nginx-proxy:1.5-alpine`) plus the
operational conventions for protecting sites with basic auth and delivering
per-vhost nginx snippets. Everything below is domain-agnostic; real host names,
credentials and htpasswd files live only on the server.

## Basic auth (htpasswd/)

nginx-proxy enables basic auth for a vhost when a file named exactly after the
`VIRTUAL_HOST` exists in `/etc/nginx/htpasswd/`. This build copies `htpasswd/*`
into the image, so the flow is:

1. On the server, generate a bcrypt entry into the build context
   (files here are git-ignored via `htpasswd/.gitignore` — never commit them,
   this repository is public):

   ```bash
   docker run --rm httpd:2.4-alpine htpasswd -nbB <user> '<password>' \
     > build/nginx-proxy-prod/htpasswd/<domain>
   ```

2. Rebuild and recreate the proxy:

   ```bash
   docker compose build nginx-proxy && docker compose up -d
   ```

After that the whole vhost answers 401 without credentials. Path-level
exceptions are done through `vhost.d` (below).

## Delivering per-vhost configs (vhost.d named volume)

`vhost.d` is a named volume shared with the letsencrypt companion, so files are
delivered by writing into the running container:

```bash
docker exec -i nginx-proxy sh -c 'cat > /etc/nginx/vhost.d/<file>' < local-file
```

Three file kinds, all standard nginx-proxy conventions:

| File | Included at | Notes |
|---|---|---|
| `default` | server level, every vhost that has no own file | shared snippets (e.g. ACME location) |
| `<domain>` | server level, that vhost only | **replaces** `default` for the host — copy anything still needed from it |
| `<domain>_location` | inside `location /` of the vhost | nested `location` blocks are allowed |

**Regeneration rule (the usual trap):** include directives are emitted at
template-generation time — docker-gen checks file *existence*. A **new** file
needs `docker restart nginx-proxy` (or any container event) to appear in the
generated config; **edits** to an already-included file only need
`docker exec nginx-proxy nginx -s reload`.

## ACME / Let's Encrypt on nginx-proxy 1.5.x

1.5 has no built-in HTTP-01 challenge location (`ACME_HTTP_CHALLENGE_LOCATION`
appeared in 1.6). Without it challenge requests are proxied into the backend
application, which may redirect or 404 them (locale-prefix redirects are a real
case) — and issuance fails. Keep this in `vhost.d/default`:

```nginx
location ^~ /.well-known/acme-challenge/ {
    auth_basic off;
    allow all;
    root /usr/share/nginx/html;
    try_files $uri =404;
    break;
}
```

`auth_basic off` is mandatory — certificate issuance and renewal must work on
protected vhosts too. When the base image is bumped to >=1.6 this block becomes
redundant (the location is built-in and defaults to on).

## Excluding paths from basic auth

Use `<domain>_location` with nested locations; each needs its own `proxy_pass`
to the upstream (named after the `VIRTUAL_HOST`). Typical candidates: an API
with its own token auth, and browser-fetched branding files — browsers request
the web-app manifest (per spec) and favicons (Chrome quirk) *without* HTTP
credentials, so behind basic auth they 401 unless exempted:

```nginx
location ^~ /api/ {
    auth_basic off;
    proxy_pass http://example.com;
    set $upstream_keepalive false;
}
location = /manifest.webmanifest {
    auth_basic off;
    proxy_pass http://example.com;
    set $upstream_keepalive false;
}
```
