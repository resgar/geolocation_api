# Geolocation API

A small RESTful JSON API that looks up geolocation data for an IP address or
a URL/hostname, backed by [ipstack](https://ipstack.com/) and cached in
Postgres. Built with Ruby on Rails 8 (API-only mode).

## Quickstart (Docker)

Requirements: Docker and Docker Compose.

```bash
docker compose up --build
```

This builds the app image, starts Postgres, creates/migrates the
`geolocation_api_development` database, and boots the API at
`http://localhost:3000`.

Load a few sample records (no ipstack key required — these are seeded
directly rather than looked up live):

```bash
docker compose run --rm web bin/rails db:seed
```

Every endpoint requires a Bearer token, and live lookups need an ipstack
access key — both live in Rails encrypted credentials. See
**Authentication** below to set them before your first request.

```bash
curl http://localhost:3000/api/v1/geolocations
# => 401, no bearer token

curl -H "Authorization: Bearer <your api_token>" http://localhost:3000/api/v1/geolocations
# => 200
```

## API

All responses follow the [JSON:API](https://jsonapi.org/) shape
(`{ "data": { "type", "id", "attributes" } }` / `{ "errors": [...] }`).

### `POST /api/v1/geolocations`

Looks up an IP address or URL and stores the result. If that query was
already looked up before, the cached record is returned instead of hitting
the provider again.

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your api_token>" \
  -d '{"query": "8.8.8.8"}'
```

Also accepts a URL (only the host is used, e.g. `https://example.com/path`
becomes `example.com`):

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your api_token>" \
  -d '{"query": "https://github.com"}'
```

Returns `201 Created` for a new lookup, `200 OK` for a cached one, `422` for
an invalid IP/URL, `502` if the provider is unreachable or errors, `503` if
the provider isn't configured (e.g. `ipstack_api_key` missing from
credentials), and `429` if the provider's rate/usage limit has been hit.

### `GET /api/v1/geolocations`

Lists stored geolocations, most recent first. Supports `?query=` to filter
down to one.

### `GET /api/v1/geolocations/:id`

Returns a single stored record, or `404` if the id doesn't exist.

### `DELETE /api/v1/geolocations/:id`

Deletes a stored record. Returns `204 No Content`.

## Configuration

`GEOLOCATION_PROVIDER` picks which provider adapter `Geolocation::Client`
uses (default `ipstack`) — see `docker-compose.yml`'s `environment:` block.

## Architecture

- `app/models/geolocation.rb` — the persisted record.
- `app/services/geolocation/query_parser.rb` — decides whether input is an
  IP address or a URL/hostname, and normalizes it.
- `app/services/geolocation/adapters/` — one class per external provider,
  each implementing `#lookup(query) -> Hash`. `Base` documents the
  interface; `Ipstack` is the current implementation.
- `app/services/geolocation/client.rb` — the only class the rest of the app
  talks to. It picks a provider class from `GEOLOCATION_PROVIDER` (default
  `ipstack`). **To add a new provider**: create a class under
  `Geolocation::Adapters` implementing `#lookup`, register it in
  `Geolocation::Client::PROVIDERS`, and point `GEOLOCATION_PROVIDER` at it.
  Nothing else in the app needs to change.
- `app/services/geolocation/lookup_service.rb` — orchestrates a request:
  parse the query, return a cached record if one exists, otherwise call the
  client and persist the result.
- `app/services/geolocation/errors.rb` — typed errors
  (`InvalidQueryError`, `RateLimitedError`, `NotConfiguredError`,
  `ProviderUnavailableError`, `ProviderError`) that
  `ApplicationController` maps to the appropriate HTTP status, so a bad
  input, a misconfigured key, and a provider outage each fail predictably
  and distinctly instead of surfacing as a generic 500.

## Authentication & secrets

Both secrets live in Rails' **encrypted credentials**
(`config/credentials.yml.enc`):

- `api_token` — every endpoint requires `Authorization: Bearer <token>`
  matching this value (see `app/controllers/concerns/api_authentication.rb`).
  Fails closed: if `api_token` isn't set, every request is rejected — never
  silently public.
- `ipstack_api_key` — the ipstack access key used for live lookups (see
  `app/services/geolocation/client.rb`). Not needed just to browse
  seeded/cached data, only for `POST` against a query that isn't cached yet.

`config/master.key` (needed to decrypt/edit credentials) is gitignored and
was **not** pushed with this repo, so a fresh clone can't read the values set
on the original machine. Set your own:

```bash
docker compose run --rm web sh -c "rm -f config/credentials.yml.enc && bin/rails credentials:edit"
```

This generates a brand-new `config/master.key` + `config/credentials.yml.enc`
for your machine and opens the decrypted YAML in `$EDITOR` (set one, e.g.
`EDITOR=vim`, if the command errors asking for one). Add:

```yaml
api_token: whatever-you-want
ipstack_api_key: your-real-ipstack-key   # get one free at https://ipstack.com/
```

Save and exit — Rails re-encrypts the file automatically. Use `api_token`'s
value as your Bearer token from then on. (If you *are* handed the project's
real `config/master.key` out of band, skip the `rm -f` and just run
`bin/rails credentials:edit` directly to read/extend the existing file.)

## Tests

```bash
docker compose run --rm -e RAILS_ENV=test web sh -c "bin/rails db:prepare && bin/rails test"
```

Controller tests stub `Rails.application.credentials` directly (see
`test/controllers/api/v1/geolocations_controller_test.rb`), so they don't
need a real `config/master.key`.

ipstack calls are replayed from checked-in VCR cassettes
(`test/vcr_cassettes/`, one per test, matched on request method + URI) rather
than hitting the real API — no real network calls or API key are needed to
run the suite. VCR's default record mode is `:none`, so an unmatched request
raises immediately instead of silently falling through to a live HTTP call.
The tests that simulate a connection timeout are the deliberate exception:
VCR cassettes represent completed exchanges, not connection failures, so
those stub the timeout directly with WebMock instead.

## Running without Docker

Requires Ruby (see `.ruby-version`) and a local Postgres.

```bash
bundle install
bin/rails db:prepare
bin/rails server
```
