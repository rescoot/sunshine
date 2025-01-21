#!/bin/bash

. ./api_test.env

while true; do
  # Generate some varying mock data
  SPEED=$(( RANDOM % 50 ))
  LAT=$(echo "52.5200 + $RANDOM/10000000" | bc -l)
  LNG=$(echo "13.4050 + $RANDOM/10000000" | bc -l)
  
  curl -X POST "${API_BASE}/telemetry" \
    -H "Content-Type: application/json" \
    -H "Authorization: Token ${API_TOKEN}" \
    -H "X-Device-ID: ${SCOOTER_VIN}" \
    -d "{
      \"telemetry\": {
        \"state\": \"unlocked\",
        \"kickstand\": \"up\",
        \"seatbox\": \"closed\",
        \"blinkers\": \"off\",
        \"speed\": ${SPEED},
        \"odometer\": 1234.5,
        \"battery0_level\": 95.5,
        \"battery1_level\": 87.2,
        \"aux_battery_level\": 98.0,
        \"cbb_battery_level\": 92.3,
        \"lat\": ${LAT},
        \"lng\": ${LNG}
      }
    }" -s > /dev/null

  echo "Sent telemetry update (speed: ${SPEED} km/h)"
  sleep 5
done
