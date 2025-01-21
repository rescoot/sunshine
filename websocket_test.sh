#!/bin/bash

. api_test.env

echo "Starting websocat - please send this command manually:"
echo '{"command":"subscribe","identifier":"{\"channel\":\"ScooterChannel\"}"}'

websocat4 "ws://localhost:3000/api/v1/ws?device_id=${SCOOTER_VIN}&api_key=${API_TOKEN}"
