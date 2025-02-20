# Scooter API Documentation

## Authentication
All API endpoints (except MQTT authentication endpoints) require authentication using a bearer token in the Authorization header:

```
Authorization: Bearer <token>
```

The token must be previously generated on the web through the generate_token endpoint. Invalid or missing tokens will receive a 401 Unauthorized response.

## Endpoints

### Scooter Management

#### List Scooters
```
GET /api/v1/scooters
```
Returns a list of scooters belonging to the authenticated user.

#### Get Single Scooter
```
GET /api/v1/scooters/:id
```
Returns detailed information about a specific scooter.

#### Create Scooter
```
POST /api/v1/scooters
```
Creates a new scooter entry.

**Parameters:**
- `name` (string): Scooter name
- `vin` (string): Vehicle identification number
- `color` (string): Scooter color

#### Update Scooter
```
PUT/PATCH /api/v1/scooters/:id
```
Updates scooter information.

**Parameters:**
- `name` (string, optional)
- `vin` (string, optional)
- `color` (string, optional)

#### Delete Scooter
```
DELETE /api/v1/scooters/:id
```
Removes a scooter from the system.

### Scooter Control Operations

#### Lock Scooter
```
POST /api/v1/scooters/:id/lock
```
Sends a command to lock the scooter (go to standby and lock handlebar).

#### Unlock Scooter
```
POST /api/v1/scooters/:id/unlock
```
Sends a command to unlock the scooter (unlock handlebar and turn on).

#### Control Blinkers
```
POST /api/v1/scooters/:id/blinkers
```
Controls the scooter's blinker lights.

**Parameters:**
- `state` (string): Must be one of the valid blinker states

#### Honk Horn
```
POST /api/v1/scooters/:id/honk
```
Activates the scooter's horn.

### Trip Management

#### Start Trip
```
POST /api/v1/scooters/:scooter_id/trips
```
Initiates a new trip record.

**Parameters:**
- `lat` (float): Starting latitude
- `lng` (float): Starting longitude

#### End Trip
```
POST /api/v1/scooters/:scooter_id/trips/end
```
Completes an ongoing trip.

**Parameters:**
- `lat` (float): Ending latitude
- `lng` (float): Ending longitude
- `distance` (float): Total trip distance
- `avg_speed` (float): Average speed during trip

## Response Format

### Success Responses
- List/Show operations return JSON objects/arrays
- Create operations return 201 Created with the created resource
- Update operations return 200 OK with the updated resource
- Delete operations return 204 No Content
- Command operations return:
```json
{
  "status": "success",
  "queued": false
}
```

### Error Responses
- 400 Bad Request: Invalid parameters
- 401 Unauthorized: Invalid or missing authentication
- 403 Forbidden: Insufficient permissions
- 404 Not Found: Resource not found
- 422 Unprocessable Entity: Validation errors
```json
{
  "errors": {
    "field_name": ["error_message"]
  }
}
```
