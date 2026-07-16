# Deploying to Production: Step-by-Step Guide

This guide walks through deploying the Decidim application to production,
end to end, using the files in this repository: `docker-compose.yml` (dev,
unchanged), `docker-compose.prod.yml` (production overlay), `.env-example`
(reference for environment variables), and `Makefile` (`prod-*` targets).

## Prerequisites

- A server with Docker and Docker Compose installed.
- This repository checked out on that server.
- A domain name pointing to the server's public IP.
- A reverse proxy (Traefik, nginx, Caddy, or similar) installed on the
  server, separate from this stack. `docker-compose.prod.yml` does not
  include one - `app` only exposes port 3000 internally, on the Docker
  network, and expects something in front of it to terminate TLS and
  forward traffic from 80/443.
- Access to the existing `config/master.key` from the Decidim application
  (needed for `RAILS_MASTER_KEY`, see step 3).
- SMTP credentials for outgoing mail.

## Step 1: Build the application image

```bash
make build
```

This builds `decidim-app:3.4.0` using the multi-stage `Dockerfile`
(precompiled assets, non-root user, cleaned build artifacts). `3.4.0` is
just this build's Docker image tag, set at the top of the `Makefile`
(`image_name`, `image_tag`) - it is not the Decidim gem version, which is
set in the `Gemfile` and unaffected by changing this tag.

## Step 2: Generate a secret key

```bash
openssl rand -hex 64
```

Keep this value for step 3 (`SECRET_KEY_BASE`).

## Step 3: Create and fill in the environment file

```bash
cp .env-example .env
```

Edit `.env` and fill in every line marked `# required` - the app fails to
boot without these:

| Variable | Value |
|---|---|
| `DECIDIM_HOST` | the production domain, e.g. `decidim.example.org` |
| `POSTGRES_PASSWORD` | a strong, generated password |
| `SECRET_KEY_BASE` | the value generated in step 2 |
| `RAILS_MASTER_KEY` | the existing `config/master.key` content - do not generate a new one, it must match the key that encrypted `config/credentials.yml.enc` |

`RAILS_ASSET_HOST` is optional - only set it if compiled assets (CSS, JS,
images) are served from a separate host or CDN instead of `DECIDIM_HOST`.
Read by `config/environments/production.rb`. Leave empty otherwise.

`SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN` have no
default either, but the app boots fine without them - only actual mail
sending fails silently (account confirmation, admin invitations, password
resets, notifications). Fine to skip for a smoke test with no real SMTP
server; needed for any deployment people will actually use, since creating
the first organization triggers an invitation email to its admin.

The rest of the file (maps, geocoder, `SMTP_PORT`, `DECIDIM_MAILER_SENDER`,
`STORAGE_PROVIDER`, etc.) has working defaults from `secrets.yml` and can
be left as-is unless a specific behavior needs to change.

Add `.env` to `.gitignore` if not already covered by a `.env*` pattern -
it will contain real secrets once filled in.

## Step 4: Set up the reverse proxy

Configure the reverse proxy already installed on the server to forward
traffic for `DECIDIM_HOST` to `localhost:3000` (or the Docker network
address of the `app` service, depending on the proxy setup) and to
terminate TLS there. The exact configuration depends on which proxy is
in use; this repository does not provide one.

`app` binds with `rails server -b 0.0.0.0 -p 3000` (see
`docker-compose.prod.yml`) - plain host and port, no URI scheme. Puma's
rack handler only special-cases the `ssl://` scheme for `-b`; anything
else (including a `tcp://` prefix) is treated as a raw host and fails to
boot with `URI::InvalidComponentError` if it isn't. Keep that in mind
before changing this line.

## Step 5: Initialize the storage volume

```bash
make prod-init-storage
```

Fixes ownership on the `storage-data` volume (Active Storage files) so the
non-root user in the image can write to it. Only needs to run once, before
the first deploy - safe to run again on later deploys, it is a no-op if
permissions are already correct.

## Step 6: Run database migrations

```bash
make prod-migrate
```

Runs `db:create` (safe no-op if the database already exists) then
`db:migrate` inside a one-off container. Required before the first start,
and again on every subsequent deploy that includes new migrations.

## Step 7: Start the application

```bash
make prod-up
```

Starts `database`, `redis`, `memcached`, `sidekiq`, and `app`. Equivalent
to steps 5-7 combined:

```bash
make prod-deploy
```

## Step 8: Verify

```bash
make prod-status
make prod-logs
```

Confirm all containers are running and `app` logs show no startup errors.
Visit `https://<DECIDIM_HOST>` through the reverse proxy to confirm the
site loads.

## Step 9: Create the first organization

The application starts with an empty database (`db_migrate` only runs
schema migrations, no seed data is loaded in production). Create a system
admin first, from the Rails console:

```bash
make prod-console
```

```ruby
Decidim::System::Admin.create!(
  email: "you@example.org",
  password: "a-strong-password",
  password_confirmation: "a-strong-password"
)
```

Then visit `https://<DECIDIM_HOST>/system` and log in with those
credentials to create the organization. This creates a `Decidim::User`
with `admin: true` for that organization and sends it an invitation email
- this is a separate flow from the system admin above, and separate from
  plain email confirmation. **Without SMTP configured, that email never
  arrives, and the account cannot sign in until the invitation is
  explicitly accepted** (confirming the email alone, e.g. via `user.confirm`,
  is not enough - Devise Invitable tracks invitation acceptance as its own
  state). To accept it from the console instead of email:

```ruby
user = Decidim::User.find_by(email: "org-admin@example.org")
user.deliver_invitation                    # generates a fresh invitation token
token = user.raw_invitation_token           # only readable right after deliver_invitation
result = Decidim::User.accept_invitation!(
  invitation_token: token,
  password: "a-strong-password",            # must differ from any password
  password_confirmation: "a-strong-password" # already set on this user, or
)                                            # this fails with "Password cannot
puts result.errors.full_messages            # reuse old password"
```

Check `result.errors.full_messages` is empty and `result.invitation_accepted_at`
is set before trying to sign in. If the organization form set an initial
password, `accept_invitation!` needs a *different* one - Devise's password
history check rejects reusing it, even the very first time.

## Redeploying (subsequent updates)

For any deploy after the first one:

```bash
make build            # rebuild the image with the new code
make prod-migrate     # apply any new migrations
make prod-restart     # restart app and sidekiq with the new image
```

`prod-restart` does not touch `database`, `redis`, or `memcached` - only
`app` and `sidekiq` are recreated.

## Restoring data from an existing environment

If this deployment is replacing an existing Decidim instance rather than
starting fresh (e.g. migrating from another host), see `MIGRATION-GUIDE.md`
instead of continuing with Step 9 above - it covers the same territory
(building the image, filling in `.env`, the reverse proxy) plus the actual
data restore, and has been tested end to end against a real dump. Restoring
onto a database that Step 6 above has already migrated will fail - the two
guides diverge specifically at that point, so don't mix steps between them.

## Troubleshooting

- **`make prod-migrate` fails with a connection error**: `database` may
  not be ready yet. Run `make prod-status` to confirm it is up, then retry.
- **App container exits immediately**: check `make prod-logs` - a missing
  required `.env` value (`SECRET_KEY_BASE` in particular) causes Rails to
  fail at boot.
- **Mail not sending**: confirm `SMTP_ADDRESS`, `SMTP_USERNAME`,
  `SMTP_PASSWORD`, `SMTP_DOMAIN` are set in `.env` - they have no fallback
  default and fail silently if left empty. The app still boots and runs
  without them; only actual mail delivery is affected.
- **Reverse proxy returns 502/504**: confirm `app` is actually running
  (`make prod-status`) and that the proxy is pointed at the right
  host/port for the `app` container.
- **"You may need to update your application code..." / a host-related
  notice appears after creating an organization, but the organization is
  still created and visible**: this did not block anything in testing -
  the organization list and admin flow kept working. Not fully diagnosed;
  if it turns out to matter, `config.hosts` is empty in this codebase's
  `config/environments/production.rb` (confirmed by grep), so Rails' own
  host allowlist is not the cause.
- **`accept_invitation!` (Step 9) returns an object with
  `"Password cannot reuse old password"` in `errors.full_messages`**: use
  a password different from whatever was set earlier in the same session
  (e.g. via the organization creation form) - Devise's password-reuse
  check applies even the first time a password is set through this path.