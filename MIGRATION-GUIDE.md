# Migrating from OSP-Hosted Decidim to Self-Hosting

This guide is for an existing OSP client moving their Decidim platform from
OSP's hosting to their own server, using the files in this repository.

**Status: tested end to end, on the same Decidim/PostgreSQL versions as
the real migration target.** The test that validated Steps 6-8 exported a
local dev instance (`docker-compose.yml`, Postgres 17.6, running the same
`Dockerfile`/`Gemfile` as this repo - Decidim 0.29) with 126 users, 53
proposals, and 13,212 Active Storage files, and restored it into the prod
overlay successfully. `decidim-app:3.4.0` (seen throughout this repo's
files) is just this build's Docker image tag, set by `image_tag` in the
`Makefile` - it is unrelated to the Decidim gem version (0.29) actually
installed inside that image. Don't confuse the two: what matters for
migration compatibility is the Decidim gem version, not this tag. The
three points marked **"Learned from testing"** below are real failures
hit during that test, not theoretical risks - read them before running
the corresponding step.

If the OSP-hosted source instance you're migrating from runs a patched or
slightly different `0.29` (extra OSP modules, custom migrations not in
this codebase's `Gemfile`), that difference wasn't exercised by this test
either, the dev instance used to validate this guide was built from the
exact same `Dockerfile`/`Gemfile` as the target, not a separate OSP
production checkout.

Data volume and shape (invitation counts, OAuth connections, years of
accumulated content) will differ between a dev/seed dataset and a real
production instance, the mechanics proven here (schema handling,
`--no-owner`, file restore) don't change with scale, but larger datasets
take longer and are worth a dry run on a copy first if you want to
minimize downtime during the actual cutover.

## What you need before starting

- A server with Docker and Docker Compose already installed.
- A domain name you control, with its DNS pointed at that server's public
  IP (a subdomain of an existing domain works fine).
- Ports 80 and 443 open on that server, reachable from the internet (check
  with your hosting provider if unsure - some consumer connections or
  mobile/CGNAT setups cannot do this at all, in which case you need a
  different network setup, e.g. a tunnel service, not covered here).
- A reverse proxy you're comfortable configuring (Traefik, nginx, Caddy) -
  this repository does not provide one; see Step 5.
- SMTP credentials for outgoing mail (your own provider, or a transactional
  email service). Required for real use - without it, invitation and
  notification emails silently fail to send.
- From OSP: a PostgreSQL dump in custom format (`pg_dump -Fc`) of your
  current database, and the Active Storage files (uploaded images,
  documents, attachments) from your current instance.
- Your existing `config/master.key` from the OSP-hosted app. This decrypts
  `config/credentials.yml.enc` and must carry over unchanged - request it
  from OSP if you don't already have it. Using the same key was confirmed
  to make encrypted-data restore frictionless in testing.
- This repository (`docker-compose.yml`, `docker-compose.prod.yml`,
  `.env-example`, `Makefile`) checked out on the server.

## Step 1: Build the application image

```bash
make build
```

Builds `decidim-app:3.4.0` from the multi-stage `Dockerfile` (precompiled
assets, non-root user). `3.4.0` is just this build's image tag (set by
`image_name`/`image_tag` at the top of the `Makefile`), not the Decidim
gem version, check the `Gemfile` if you need to know which Decidim
version is actually installed.

## Step 2: Generate a secret key

```bash
openssl rand -hex 64
```

Keep this for Step 3 - it becomes `SECRET_KEY_BASE`. Generate a new one
even though you're migrating: it protects Rails sessions/cookies for this
specific deployment, and is unrelated to `RAILS_MASTER_KEY` below.

## Step 3: Create and fill in the environment file

```bash
cp .env-example .env
```

Fill in every line marked `# required`:

| Variable | Value |
|---|---|
| `DECIDIM_HOST` | your domain, e.g. `participation.example.org` |
| `POSTGRES_PASSWORD` | a strong, generated password (new, does not need to match anything from OSP) |
| `SECRET_KEY_BASE` | the value from Step 2 |
| `RAILS_MASTER_KEY` | **your existing `config/master.key` content from OSP - not a new one.** Encrypted columns in your restored data (Step 7) will fail to decrypt if this doesn't match what encrypted them originally. |

Fill in `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`
with real credentials - unlike a throwaway test, this deployment needs to
actually send mail (password resets, notifications, admin invitations for
new users after the migration).

`RAILS_ASSET_HOST` and the maps/geocoder section have working defaults;
leave them as-is unless you specifically need different behavior than
your OSP-hosted instance had.

Add `.env` to `.gitignore` if not already covered by a `.env*` pattern.

## Step 4: Copy over the dump and files

Copy the `pg_dump` file and the Active Storage files from OSP onto this
server, anywhere convenient (e.g. `~/migration/dump.pgcustom` and
`~/migration/storage/`). Don't restore them yet.

## Step 5: Set up the reverse proxy

Point your reverse proxy's config at `DECIDIM_HOST`, forwarding to
`app` on port 3000, with TLS terminated at the proxy. `app` itself binds
with `rails server -b 0.0.0.0 -p 3000` (plain HTTP, no scheme) - see
`docker-compose.prod.yml`. The exact proxy config depends on which one
you're using; this repository doesn't include one.

## Step 6: Initialize storage and create an empty database

```bash
make prod-init-storage
make prod-create-db
```

**Learned from testing: do not run `make prod-migrate` at this stage.**
The first version of this guide migrated the schema before restoring the
dump. In testing, that caused `pg_restore --clean` to fail with cascading
errors (`cannot drop constraint decidim_users_pkey ... other objects
depend on it`, then `relation "decidim_users" already exists`) -
`pg_restore` doesn't reliably order `DROP` statements around foreign-key
dependencies when targeting a database that already has its own schema.
`prod-create-db` only runs `db:create`, leaving the database empty (no
tables) so `pg_restore` can build the schema itself from the dump, in the
order it already knows works.

## Step 7: Restore the database dump

```bash
make prod-restore-dump DUMP=~/migration/dump.pgcustom DB=osp_app
```

Replace `osp_app` with your actual database name if it differs - it's
not set by an environment variable in this project; check
`config/database.yml` or ask OSP what database name their instance used.

**Learned from testing, two changes from a "default" `pg_restore`
invocation, already applied by this Makefile target:**
- **No `--clean`/`--if-exists`.** Only safe to use against a database that
  already has the old schema loaded (which Step 6 deliberately avoids).
  Against an empty database, plain `pg_restore` (no `--clean`) is what
  worked without errors.
- **`--no-owner` is required.** The dump was taken with a local PostgreSQL
  user (e.g. your own OS username) as the table owner. That role doesn't
  exist in the production container (which only has `postgres`), so
  without `--no-owner`, every `ALTER TABLE ... OWNER TO <that user>`
  statement fails - around 370 errors in testing, one per table/sequence.
  `--no-owner` skips those statements entirely; ownership defaults to the
  connecting user (`postgres`), which is what the app expects anyway.

A clean run produces no `pg_restore: error` lines and no final
"errors ignored on restore" summary. Verify counts directly rather than
trusting silence alone:

```bash
make prod-shell
```
```bash
bundle exec rails runner 'puts Decidim::Organization.count; puts Decidim::User.count'
```

If the dump predates this codebase's current migrations, run
`make prod-migrate` once more after the restore completes, to apply any
newer migrations on top of the restored schema.

## Step 8: Restore the Active Storage files

```bash
make prod-restore-storage SRC=~/migration/storage
```

Verify the count matches your source directory:

```bash
docker run --rm -v decidim-app_storage-data:/dest alpine sh -c "find /dest -type f | wc -l"
```

The imported `active_storage_blobs`/`active_storage_attachments` rows
(from the SQL dump) must reference files that actually exist at these
paths (the `key` column is the file path within the volume) - a mismatch
breaks images, attachments, and file downloads without an obvious error
elsewhere, so the file count check above is worth doing even though it
only proves the count matches, not that every path lines up.

**If OSP's source instance used object storage (S3/GCS/Azure) instead of
local disk.** `make prod-restore-storage` copies files as-is into the
`storage-data` volume, which only works if the source already has the
same directory layout Active Storage's `DiskService` expects. It does not
- confirmed by reading Rails' source directly: `DiskService` derives a
`prefix1/prefix2/` subfolder from each file's key (first two, then next
two characters, e.g. key `8x2jhtmb33u0kcsyrb9vmwf7gp0w` lives at
`8x/2j/8x2jhtmb33u0kcsyrb9vmwf7gp0w`), while `S3Service` stores the same
key flat, with no such subfolder. A plain `aws s3 sync` download followed
by a plain copy will produce a flat directory that `DiskService` cannot
read - files would upload fine but every existing attachment would 404.

Reshard the flat export before copying it in:

```bash
aws s3 sync s3://your-bucket-name ./s3-flat-export
```

```bash
#!/bin/bash
# s3_to_disk.sh - reshards a flat S3 export into the layout DiskService expects
set -euo pipefail
SRC="$1"; DEST="$2"
mkdir -p "$DEST"
find "$SRC" -maxdepth 1 -type f | while read -r file; do
  key=$(basename "$file")
  target_dir="$DEST/${key:0:2}/${key:2:2}"
  mkdir -p "$target_dir"
  cp "$file" "$target_dir/$key"
done
```

```bash
chmod +x s3_to_disk.sh
./s3_to_disk.sh ./s3-flat-export ./storage-resharded
make prod-restore-storage SRC=./storage-resharded
```

**The resharding logic itself is verified against Rails' `DiskService`
source, but the end-to-end path (S3 export - reshard - volume - app
serving the file) was not run against a real bucket in testing** (the
dev instance used to validate this guide stored files locally
throughout) - budget time to confirm on a few files before trusting it
at scale. The reverse migration (this deployment using object storage
instead of local disk) is a separate, untested case: set
`STORAGE_PROVIDER` and the relevant provider credentials in `.env`, and
confirm the configured service in `config/storage.yml` matches - no
resharding is needed in that direction since `S3Service` expects the flat
layout natively.

## Step 9: Reconcile environment-specific data

Your restored data still has values pointing at the old OSP environment:

```bash
make prod-console
```

```ruby
org = Decidim::Organization.first
puts org.host
```

**Learned from testing: this isn't just an SEO/link-correctness detail -
a mismatched host blocks admin actions too.** With `org.host` still set
to OSP's old domain, the public site was reachable at the new domain, but
clicking "Edit" on the organization in the `/system` panel silently did
nothing (the page just reloaded the system view, no error shown). Fixing
the host resolved both the public-site mismatch and the admin panel
issue:

```ruby
org.update!(host: "participation.example.org")  # your actual DECIDIM_HOST
```

Then check for users with pending, never-accepted invitations from the
OSP instance:

```ruby
Decidim::User.where.not(invitation_sent_at: nil).where(invitation_accepted_at: nil).count
```

If this is non-zero, those accounts cannot sign in until their invitation
is accepted. There's no bulk fix in this repository; each one needs the
same manual steps as a fresh install's first admin (see
`DEPLOYMENT-GUIDE.md` Step 9 for the exact `deliver_invitation` /
`accept_invitation!` sequence) - or, since SMTP is configured this time
(Step 3), you could instead re-trigger their invitation email with
`user.deliver_invitation` and let them accept it normally.

## Step 10: Start the application

```bash
make prod-up
```

Starts `database`, `redis`, `memcached`, `sidekiq`, `app`.

## Step 11: Verify

```bash
make prod-status
make prod-logs
```

Visit `https://<DECIDIM_HOST>` through your reverse proxy. Confirm:
- The homepage loads and shows your organization's actual content (not an
  empty/default one).
- Images and attachments load (confirms Step 8 worked).
- You can sign in with an existing account (confirms Step 9 worked for
  that account).
- The `/system` panel's "Edit" action on the organization actually saves
  changes (confirms the host fix in Step 9 took effect for admin actions,
  not just the public site).
- A test email (e.g. password reset) actually arrives (confirms Step 3's
  SMTP settings work).

## Ongoing: redeploying after this initial migration

For any update after this migration is live:

```bash
make build
make prod-migrate
make prod-restart
```

`prod-restart` only recreates `app` and `sidekiq`, leaving `database`,
`redis`, and `memcached` untouched.

## Troubleshooting

See the Troubleshooting section in `DEPLOYMENT-GUIDE.md` for issues
related to the base deployment (build, boot, bind address, invitations).
Migration-specific issues:

- **`pg_restore` reports "cannot drop constraint ... other objects depend
  on it" followed by "relation already exists"**: you ran `make
  prod-migrate` before restoring, or restored onto a database that
  already had a schema loaded. Start over: drop the volumes
  (`make prod-down` then remove the volumes, or `docker compose down -v`),
  run `make prod-init-storage` and `make prod-create-db` (not
  `prod-migrate`), then `make prod-restore-dump` again (see Step 6-7).
- **~370 `pg_restore: error: role "X" does not exist` messages**: you
  restored with a raw `pg_restore` command missing `--no-owner`. Use
  `make prod-restore-dump DUMP=... DB=...` (Step 7), which already
  includes it.
- **Homepage loads but shows no content / a fresh-looking install**: the
  restore likely didn't apply, or applied to the wrong database. Confirm
  the `DB=` value passed to `make prod-restore-dump` (Step 7) matches what
  `config/database.yml` resolves to for this app, and check row counts
  directly (see Step 7) rather than trusting a lack of visible errors.
- **Images or attachments are broken**: Active Storage files (Step 8)
  don't match the blob records restored from the SQL dump. Confirm
  `make prod-restore-storage` was pointed at the right source directory,
  and that the file count matches.
- **Encrypted fields raise decryption errors, or look like garbage**:
  `RAILS_MASTER_KEY` (Step 3) doesn't match the key OSP's instance used.
  Confirm you copied `config/master.key` exactly, with no extra
  whitespace or line endings added.
- **Clicking "Edit" on the organization in `/system` does nothing (page
  just reloads)**: `org.host` (Step 9) doesn't match the domain you're
  accessing the app from. Fix it in the Rails console and retry.
- **Existing users can't sign in after migration**: check
  `invitation_accepted_at` for that user (Step 9) - a never-accepted
  invitation blocks sign-in independently of password or email
  confirmation status.
