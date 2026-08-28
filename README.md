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

```bash
curl http://localhost:3000/api/v1/geolocations
```

A live lookup (`POST`) needs an ipstack access key set in Rails encrypted
credentials as `ipstack_api_key` (`bin/rails credentials:edit`).

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
  -d '{"query": "8.8.8.8"}'
```

Also accepts a URL (only the host is used, e.g. `https://example.com/path`
becomes `example.com`):

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Content-Type: application/json" \
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

## Architecture

- `app/models/geolocation.rb` — the persisted record.
- `app/services/geolocation/query_parser.rb` — decides whether input is an
  IP address or a URL/hostname, and normalizes it.
- `app/services/geolocation/client.rb` — talks to ipstack and normalizes its
  response into attributes matching the `Geolocation` model.
- `app/services/geolocation/lookup_service.rb` — orchestrates a request:
  parse the query, return a cached record if one exists, otherwise call the
  client and persist the result.
- `app/services/geolocation/errors.rb` — typed errors
  (`InvalidQueryError`, `RateLimitedError`, `NotConfiguredError`,
  `ProviderUnavailableError`, `ProviderError`) that
  `ApplicationController` maps to the appropriate HTTP status, so a bad
  input, a misconfigured key, and a provider outage each fail predictably
  and distinctly instead of surfacing as a generic 500.

## Tests

```bash
docker compose run --rm -e RAILS_ENV=test web sh -c "bin/rails db:prepare && bin/rails test"
```

ipstack calls are stubbed with WebMock — no real network calls or API key
are needed to run the suite.

## Running without Docker

Requires Ruby (see `.ruby-version`) and a local Postgres.

```bash
bundle install
bin/rails db:prepare
bin/rails server
```
