#!/bin/bash

. .env

set -ex

blinkers=${1:-off}

mosquitto_pub -h localhost -p 1883 -u $MQTT_SCOOTER_TEST_USER -P $MQTT_SCOOTER_TEST_PASS -t 'scooters/REUNU-TEST-VOID/telemetry' -m \
  '{"state": "parked", "kickstand": "down", "seatbox": "closed", "blinkers": "'${blinkers}'", "speed": 0, "battery0_level": 58.0, "battery1_level": 24.5, "aux_battery_level": 75.0, "cbb_battery_level": 98.0, "lat": 52.5200, "lng": 13.4050 }'