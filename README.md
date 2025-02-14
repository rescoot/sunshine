# Sunshine ☀️

Sunshine is an open source Rails application for managing unu/librescoot electric scooters. It provides a web interface and API for monitoring telemetry data, tracking trips, and controlling scooter functionality.

## Features

- Real-time telemetry monitoring via MQTT
- Trip tracking and statistics
- User management with owner/user roles
- API with token-based authentication
- Admin dashboard with debugging tools

## Requirements

- Ruby 3.2 or higher
- Redis 7.0 or higher
- Mosquitto MQTT broker with authentication

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/rescoot/sunshine.git
cd sunshine
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
rails db:create db:migrate
```

4. Start Redis:
```bash
docker compose start redis
```

5. Start the Rails server:
```bash
bin/dev
```

## Deployment

This application is designed to be deployed using [Kamal](https://kamal-deploy.org/). 

1. First, set up your production environment variables in `.env.production`:
```bash
KAMAL_REGISTRY_USERNAME=your-username
KAMAL_REGISTRY_PASSWORD=your-token
RAILS_ENV=production
REDIS_URL=redis://localhost:6379/1
SECRET_KEY_BASE=your_secret_key_base
MQTT_HOST=mqtt.yourdomain.com
MQTT_PORT=8883
MQTT_USERNAME=cloud_service
MQTT_PASSWORD=your_mqtt_password
MQTT_SSL=true
```

2. Check `config/deploy.yml`

3. Deploy:
```bash
kamal setup  # first run only
kamal deploy
```

### MQTT Setup

The application requires a Mosquitto MQTT broker with authentication configured. Here's how to set it up:

1. Install Mosquitto:
```bash
apt install mosquitto mosquitto-clients
```

2. Generate certificates using the provided Rake tasks (optional):
```bash
# Create CA certificate (adjust organization and country as needed)
rails mqtt_certs:create_ca[Rescoot,DE]

# Generate server certificate
rails mqtt_certs:create_server

# Generate client certificate (for each client)
rails mqtt_certs:create_client[client_name]

# Extract public certificates for distribution (not currently needed)
rails mqtt_certs:extract_public
```

This will create certificates in `config/mqtt_certs` with the following structure:
```
config/mqtt_certs/
├── ca.crt           # CA certificate
├── ca.key           # CA private key (keep secure!)
├── clients/         # Client certificates
│   └── client_name/
│       ├── client.crt
│       └── client.key
├── public/          # Public certificates for distribution
│   ├── ca.crt
│   └── server.crt
└── server/          # Server certificates
    ├── server.crt
    └── server.key
```

Keep all private keys (*.key files) secure and never distribute them.

Or use openssl directly:
```bash
# Create CA key and certificate
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt

# Create server key and certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
```

3. Configure Mosquitto in `config/mosquitto/default.conf`.

Remove `cafile`, `certfile`, `keyfile` if you're not using your own CA.

4. Optional: Set up DynSec authentication:
```bash
# Initialize DynSec config
mosquitto_ctrl dynsec init /etc/mosquitto/dynamic-security.json admin adminpassword

# Create cloud service user
mosquitto_ctrl dynsec createClient cloud_service
mosquitto_ctrl dynsec setClientPassword cloud_service your_secure_password

# Create scooter user
mosquitto_ctrl dynsec createClient radio-gaga-YOUR_SCOOTER_VIN
mosquitto_ctrl dynsec setClientPassword radio-gaga-YOUR_SCOOTER_VIN your_secure_password

# Set up ACLs for telemetry topics
mosquitto_ctrl dynsec createRole telemetry_publisher
mosquitto_ctrl dynsec addRoleACL telemetry_publisher publishClientTopic "scooters/%c/telemetry"
mosquitto_ctrl dynsec addClientRole radio-gaga-YOUR_SCOOTER_VIN telemetry_publisher
```

5. Restart Mosquitto:
```bash
kamal accessory boot mqtt
# or if not using kamal
systemctl restart mosquitto
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILS_ENV` | Rails environment | development |
| `REDIS_URL` | Redis connection URL | redis://localhost:6379/1 |
| `MQTT_HOST` | MQTT broker hostname | localhost |
| `MQTT_PORT` | MQTT broker port | 8883 |
| `MQTT_USERNAME` | MQTT broker username | - |
| `MQTT_PASSWORD` | MQTT broker password | - |
| `MQTT_SSL` | Enable SSL for MQTT | true |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
