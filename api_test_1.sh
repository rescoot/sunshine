#!/bin/bash

. ./api_test.env

set -ex

# Test telemetry update
curl -vX POST "${API_BASE}/telemetry" \
  -H "Content-Type: application/json" \
  -H "Authorization: Token ${API_TOKEN}" \
  -H "X-Device-ID: ${SCOOTER_VIN}" \
  -d '{
    "telemetry": {
      "state": "unlocked",
      "kickstand": "down",
      "seatbox": "closed",
      "blinkers": "off",
      "speed": 0,
      "odometer": 1234.5,
      "battery0_level": 95.5,
      "battery1_level": 87.2,
      "aux_battery_level": 98.0,
      "cbb_battery_level": 92.3,
      "lat": 52.5200,
      "lng": 13.4050
    }
  }'

exit

# Start a new trip
curl -X POST "${API_BASE}/trips/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Token ${API_TOKEN}" \
  -H "X-Device-ID: ${SCOOTER_VIN}" \
  -d '{
    "lat": 52.5200,
    "lng": 13.4050
  }'

# End a trip
curl -X POST "${API_BASE}/trips/end" \
  -H "Content-Type: application/json" \
  -H "Authorization: Token ${API_TOKEN}" \
  -H "X-Device-ID: ${SCOOTER_VIN}" \
  -d '{
    "lat": 52.5300,
    "lng": 13.4150,
    "distance": 3500,
    "avg_speed": 15.2
  }'
