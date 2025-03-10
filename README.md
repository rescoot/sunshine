# Sunshine ☀️

Sunshine is an open source Rails application for managing unu/librescoot electric scooters. It provides a web interface and API for monitoring telemetry data, tracking trips, and controlling scooter functionality.

## Sponsorship

| [![Starsong Consulting Avatar](https://avatars.githubusercontent.com/u/166622226?s=48)](https://starsong.eu/) | This project is sponsored by [Starsong Consulting](https://starsong.eu/). |
|-|-|

## Features

- Real-time telemetry monitoring via MQTT
- Trip tracking and statistics
- User management with owner/user roles
- API with token-based authentication
- Admin dashboard with debugging tools
- Remote scooter control (lock, unlock, blinkers, honk, seatbox, etc.)
- Achievements system with various challenges and rewards (including configurable secret achievements)
- Leaderboards with user rankings and statistics
- Two-factor authentication (2FA) for enhanced security
- Internationalization/localization support

## Requirements

- Ruby 3.2 or higher
- Redis 7.0 or higher (for caching, background jobs, and real-time updates)
- Mosquitto MQTT broker with authentication (for scooter communication)

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
./bin/rails db:create db:migrate
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
# Kamal registry credentials
KAMAL_REGISTRY_USERNAME=your-username
KAMAL_REGISTRY_PASSWORD=your-token

# Docker image
IMAGE_NAME=your-registry/your-image

# Server IPs
WEB_SERVER_IP=your-web-server-ip
JOB_SERVER_IP=your-job-server-ip
MQTT_SERVER_IP=your-mqtt-server-ip

# Builder configuration
DEPLOY_USER=your-deploy-user
DEPLOY_HOST=your-deploy-host

# Domain names
PRIMARY_DOMAIN=your-primary-domain
SUNSHINE_DOMAIN=your-sunshine-domain
UNU_DOMAIN=your-unu-domain
UNU_CLOUD_DOMAIN=your-unu-cloud-domain

# Rails configuration
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
REDIS_URL=redis://sunshine-redis:6379/1

# SMTP configuration
SMTP_ADDRESS=your-smtp-address
SMTP_PASSWORD=your-smtp-password

# MQTT configuration
MQTT_HOST=your-mqtt-host
MQTT_PORT=your-mqtt-port
MQTT_SSL=true
MQTT_USERNAME=your-mqtt-username
MQTT_PASSWORD=your-mqtt-password
```

You can use the provided `.env.production.example` as a template.

2. Deploy:
```bash
source .env.production  # or use `dotenv`
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

# Optional, if you want to use client cert auth: Generate client certificate (for each client)
rails mqtt_certs:create_client[client_name]

# Optional: Extract public certificates for distribution (not currently needed)
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

4. Set up DynSec authentication. See `config/mosquitto/dynamic-security.json` for a baseline.

5. Restart Mosquitto:
```bash
kamal accessory reboot mqtt
# or if not using kamal
systemctl restart mosquitto
```

## Achievement System

Sunshine includes an achievement system that rewards users for various activities like distance traveled, trips completed, and special milestones. The system includes both regular achievements (visible to all users) and secret achievements (only revealed after being earned).

### Configuring Achievements

Achievements are configured using YAML files in the `config/achievements` directory:

- `default.yml`: Contains regular (non-secret) achievements that are visible to users before they earn them.
- `secret.yml.example`: Contains example secret achievements. These are not visible to users until they earn them.
- `secret.yml`: The actual secret achievements used by your instance. This file is gitignored and should not be committed to the repository.

To set up secret achievements for your instance:

1. Copy the example file to create your own secret achievements file:
   ```bash
   cp config/achievements/secret.yml.example config/achievements/secret.yml
   ```

2. Edit `secret.yml` to customize your secret achievements.

3. The `secret.yml` file will be loaded automatically when the application starts.

See `config/achievements/README.md` for more details on the achievement format and configuration options.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
