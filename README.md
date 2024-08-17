# Geolocation API

## Installation

1. Create a .env file and add your IPStack API key:
   ```bash
   IPSTACK_API_KEY=your_ipstack_api_key

2. Build the Docker image and start the containers:
    ```bash
   docker compose build
   docker compose up

3. Create the database and run migrations:
    ```bash
    docker compose run web rails db:create
    docker compose run web rails db:migrate

## Testing
    docker compose run web rails test

## API Endpoints

### `POST /geolocations`

Create a new geolocation record by IP address.

**Request Body:**
  
```json
{
    "geolocation": {
        "ip_address": "142.251.41.78"
    }
}
```
Or by URL:  
```json
{
    "geolocation": {
        "url": "www.google.com"
    }
}

```

### `GET /geolocations`

Retrieve a geolocation record by IP address.

**Request Body:**

```json
{
  "ip_address": "142.251.41.78"
}
```
Or by URL:  
```json
{
  "url": "www.google.com"
}
```

### `DELETE /geolocations`

Delete a geolocation record by IP address:

**Request Body:**

```json
{
  "ip_address": "142.251.41.78"
}
```
Or by URL:  
```json
{
  "url": "www.google.com"
}
```
