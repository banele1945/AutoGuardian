# Server-Side Endpoints for Trip Tracking

## Required Endpoints

### 1. GET /api/trips/:device_uid/dates
**Purpose**: Fetch available dates that have trips
**Authentication**: JWT required
**Response**:
```json
{
  "dates": ["2025-01-30", "2025-01-29", "2025-01-28"]
}
```

### 2. GET /api/trips/:device_uid?date=YYYY-MM-DD
**Purpose**: Fetch trips for a specific date
**Authentication**: JWT required
**Query Parameters**: `date` (required)
**Response**:
```json
{
  "trips": [
    {
      "id": 1,
      "device_uid": "ESP32-123456",
      "trip_number": 1,
      "start_time": "2025-01-30T08:00:00.000Z",
      "end_time": "2025-01-30T09:30:00.000Z",
      "start_location": "Home",
      "end_location": "Office",
      "distance": 15.5,
      "average_speed": 45.2,
      "max_speed": 80.0,
      "fuel_consumed": 2.3,
      "idle_time": 300,
      "stops_count": 2,
      "status": "completed"
    }
  ]
}
```

### 3. GET /api/trips/:device_uid/:trip_id
**Purpose**: Fetch detailed information for a specific trip
**Authentication**: JWT required
**Response**:
```json
{
  "trip": {
    "id": 1,
    "device_uid": "ESP32-123456",
    "trip_number": 1,
    "start_time": "2025-01-30T08:00:00.000Z",
    "end_time": "2025-01-30T09:30:00.000Z",
    "start_location": "Home",
    "end_location": "Office",
    "distance": 15.5,
    "average_speed": 45.2,
    "max_speed": 80.0,
    "fuel_consumed": 2.3,
    "idle_time": 300,
    "stops_count": 2,
    "status": "completed",
    "route_points": [
      {"lat": -33.9249, "lng": 18.4241, "timestamp": "2025-01-30T08:00:00.000Z"},
      {"lat": -33.9250, "lng": 18.4242, "timestamp": "2025-01-30T08:01:00.000Z"}
    ]
  }
}
```

## Socket.io Events

### 1. trip_started
**Emitted when**: A new trip starts
**Payload**:
```json
{
  "device_uid": "ESP32-123456",
  "trip_number": 1,
  "start_time": "2025-01-30T08:00:00.000Z",
  "start_location": "Home"
}
```

### 2. trip_ended
**Emitted when**: A trip ends
**Payload**:
```json
{
  "device_uid": "ESP32-123456",
  "trip_number": 1,
  "end_time": "2025-01-30T09:30:00.000Z",
  "end_location": "Office",
  "distance": 15.5,
  "average_speed": 45.2
}
```

### 3. trip_updated
**Emitted when**: Trip data is updated (e.g., new route points)
**Payload**:
```json
{
  "device_uid": "ESP32-123456",
  "trip_number": 1,
  "distance": 12.3,
  "average_speed": 42.1
}
```

## Implementation Notes

1. **Date Format**: Use ISO 8601 format (YYYY-MM-DD) for dates
2. **Numeric Values**: Store as DECIMAL in MySQL, but can be returned as int or double
3. **Trip Numbers**: Should be auto-incremented per device per day
4. **Route Points**: Store as JSON array in MySQL
5. **Authentication**: Verify JWT token for all endpoints
6. **Error Handling**: Return appropriate HTTP status codes and error messages 