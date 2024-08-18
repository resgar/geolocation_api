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

Create a new geolocation record by IP address or URL.

**Request Body:**
  
```json
{
    "address": "142.251.41.78"
}
```
Or:  
```json
{
    "address": "www.google.com"
}

```

### `GET /geolocations`

Retrieve a geolocation record by IP address or URL.

**Query Parameters:**

- address (required): The IP address or URL you want to retrieve geolocation data for.

**Example Request:**

   GET http://localhost:3000/geolocations?address=142.251.41.78

   GET http://localhost:3000/geolocations?address=www.google.com

### `DELETE /geolocations`

Delete a geolocation record by IP address or URL:

**Request Body:**

```json
{
  "address": "142.251.41.78"
}
```
Or:  
```json
{
  "address": "www.google.com"
}
```
