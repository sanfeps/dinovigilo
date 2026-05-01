# DinoVigilo Backend (PocketBase)

Self-hosted PocketBase instance backing the Friends & Challenges feature.

## Layout in this repo

```
backend/
├── pb_migrations/        # JS migrations — schema + seed (versioned, source of truth)
├── pb_hooks/             # JS hooks — custom endpoints + record lifecycle
├── pocketbase.service    # systemd unit (copy to /etc/systemd/system/)
├── Caddyfile.example     # Reverse proxy + TLS template
└── deploy.sh             # rsync hooks + migrations to a host and restart
```

The schema lives entirely in `pb_migrations/` — never edit collections in the
admin UI without exporting a migration after, otherwise the file system and
the deployed DB will drift.

## First-time host setup

Tested on a Debian 12 LXC container, but any Linux host with systemd works.

```bash
# 1. System user + directories
sudo useradd -r -s /usr/sbin/nologin pocketbase
sudo mkdir -p /opt/pocketbase /var/lib/pocketbase/pb_data
sudo chown -R pocketbase:pocketbase /opt/pocketbase /var/lib/pocketbase

# 2. Download PocketBase (pin the version we run in production)
PB_VERSION=0.37.4
cd /tmp
curl -L -o pb.zip "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"
unzip pb.zip pocketbase
sudo mv pocketbase /opt/pocketbase/pocketbase
sudo chown pocketbase:pocketbase /opt/pocketbase/pocketbase
sudo chmod +x /opt/pocketbase/pocketbase

# 3. Sync hooks + migrations from this repo (run from your laptop)
cd backend
./deploy.sh <ssh-host>     # rsyncs pb_hooks/ + pb_migrations/, restarts unit

# 4. Install + enable the systemd unit
sudo cp pocketbase.service /etc/systemd/system/pocketbase.service
sudo systemctl daemon-reload
sudo systemctl enable --now pocketbase

# 5. Create the superadmin (one-off, interactive)
sudo -u pocketbase /opt/pocketbase/pocketbase \
  --dir=/var/lib/pocketbase/pb_data \
  superuser create admin@example.com 'a-strong-password'
```

Migrations run automatically on `systemctl restart pocketbase` because the
unit passes `--migrationsDir=/opt/pocketbase/pb_migrations`.

## TLS / public exposure

Two recommended patterns:

1. **Tailnet-only**: keep `pocketbase.service` bound to `127.0.0.1:8090`,
   front it with Caddy doing DNS-01 issuance against your public domain
   (template in `Caddyfile.example`). Clients reach the host over the
   tailnet (e.g. headscale, tailscale), but the cert is real.
2. **Public**: same Caddy config, but the host has a public A/AAAA record.
   Use HTTP-01 instead of DNS-01.

Either way, **never expose port 8090 directly to the public internet** — the
admin UI and superuser creation endpoint live there.

## Routine ops

```bash
# Apply new migrations or hook changes from this repo
backend/deploy.sh <ssh-host>

# Tail logs
ssh <host> journalctl -u pocketbase -f

# Inspect runtime errors (JS hook stack traces land here, NOT in journalctl)
ssh <host> sqlite3 /var/lib/pocketbase/pb_data/auxiliary.db \
  '"SELECT created, message FROM _logs WHERE level=8 ORDER BY created DESC LIMIT 20;"'

# Backup the DB (do this before risky migrations)
ssh <host> 'sudo -u pocketbase sqlite3 /var/lib/pocketbase/pb_data/data.db ".backup /tmp/pb-backup-$(date +%F).db"'
```

## Schema notes

See `project_friends_challenges.md` in Claude memory for full design context.
Key collections (all defined in `pb_migrations/`):

- `users` — auth collection extended with `username`, `displayName`,
  `avatarEmoji`, `optInScreenTime`. List/view rule: any authenticated user
  (so friend lookups can `expand=userA,userB`). PocketBase never returns
  `password`/`tokenKey`; `email` only if `emailVisibility=true`.
- `user_private` — private 1:1 sibling of `users`, holds `inviteCode`.
  Read rule scoped to the owning user — friends never see codes.
- `friendships` — `userA` (requester) / `userB` (addressee) / `status`
  (pending|accepted|blocked). Reject = delete row, accept = update status
  while pending.
- `challenges`, `challenge_objectives`, `challenge_completions`,
  `daily_summaries` — Sprint D and beyond.

## Custom endpoints (pb_hooks)

- `POST /api/friends/by-code` — addressee lookup by 6-char invite code,
  enforces no-self / no-duplicate.
- `onUserCreate` — auto-generates a unique `inviteCode` row in `user_private`.

> **JS hook gotcha**: PocketBase pulls a fresh VM from the pool per
> invocation. Top-level helpers in the file are NOT in scope inside the
> callback — inline helpers as `const` arrow functions inside the handler.
