#!/bin/bash

TOKEN="b726274f44f3da43bdcb195a3842dfa1d1fdad63026422825769a4e569275cf4"
AUTH_HEADER="Authorization: Token ${TOKEN}"

set -ex

API_URL="http://localhost:3000/api/v1"

# Create a scooter
echo "Creating scooter..."
SCOOTER_ID=$(curl -s -X POST "${API_URL}/scooters" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d '{
    "scooter": {
      "name": "Test Scooter",
      "vin": "TS123456789",
      "color": "green"
    }
  }' | jq -r '.id')

echo "Created scooter ID: ${SCOOTER_ID}"

# Get scooter details
echo -e "\nFetching scooter details..."
curl -s "${API_URL}/scooters/${SCOOTER_ID}" \
  -H "${AUTH_HEADER}" | jq '.'

# Update scooter
echo -e "\nUpdating scooter..."
curl -s -X PATCH "${API_URL}/scooters/${SCOOTER_ID}" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d '{
    "scooter": {
      "name": "Updated Test Scooter",
      "color": "blue"
    }
  }' | jq '.'

# Generate new API token for scooter
echo -e "\nGenerating API token..."
curl -s -X POST "${API_URL}/scooters/${SCOOTER_ID}/generate_token" \
  -H "${AUTH_HEADER}" | jq '.'

# Lock scooter
echo -e "\nLocking scooter..."
curl -s -X POST "${API_URL}/scooters/${SCOOTER_ID}/lock" \
  -H "${AUTH_HEADER}" | jq '.'

# Delete scooter
echo -e "\nDeleting scooter..."
curl -X DELETE "${API_URL}/scooters/${SCOOTER_ID}" \
  -H "${AUTH_HEADER}"
