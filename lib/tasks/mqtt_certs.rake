require "openssl"
require "fileutils"

namespace :mqtt_certs do
  CERT_DIR = Rails.root.join("config/mqtt_certs")

  desc "Generate CA certificate and key"
  task :create_ca, [ :org, :country ] => :environment do |t, args|
    args.with_defaults(org: "Rescoot", country: "DE")

    FileUtils.mkdir_p(CERT_DIR)

    # Generate CA private key
    ca_key = OpenSSL::PKey::RSA.new(4096)
    File.write(CERT_DIR.join("ca.key"), ca_key.to_pem)

    # Generate CA certificate
    ca_cert = OpenSSL::X509::Certificate.new
    ca_cert.version = 2
    ca_cert.serial = 1
    ca_cert.subject = OpenSSL::X509::Name.new([
      [ "C", args.country, OpenSSL::ASN1::PRINTABLESTRING ],
      [ "O", args.org, OpenSSL::ASN1::UTF8STRING ],
      [ "CN", "#{args.org} CA", OpenSSL::ASN1::UTF8STRING ]
    ])
    ca_cert.issuer = ca_cert.subject
    ca_cert.public_key = ca_key.public_key
    ca_cert.not_before = Time.now
    ca_cert.not_after = Time.now + 5.years

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = ca_cert
    extension_factory.issuer_certificate = ca_cert

    ca_cert.add_extension extension_factory.create_extension("basicConstraints", "CA:TRUE", true)
    ca_cert.add_extension extension_factory.create_extension("keyUsage", "keyCertSign,cRLSign", true)
    ca_cert.add_extension extension_factory.create_extension("subjectKeyIdentifier", "hash")

    ca_cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))
    File.write(CERT_DIR.join("ca.crt"), ca_cert.to_pem)

    puts "CA certificate and key generated in #{CERT_DIR}"
  end

  desc "Generate client certificate signed by CA"
  task :create_client, [ :name ] => :environment do |t, args|
    unless args.name
      puts "Usage: rake mqtt_certs:create_client[name]"
      exit 1
    end

    client_dir = CERT_DIR.join("clients", args.name)
    FileUtils.mkdir_p(client_dir)

    # Load CA cert and key
    ca_cert = OpenSSL::X509::Certificate.new(File.read(CERT_DIR.join("ca.crt")))
    ca_key = OpenSSL::PKey::RSA.new(File.read(CERT_DIR.join("ca.key")))

    # Generate client key
    client_key = OpenSSL::PKey::RSA.new(2048)
    File.write(client_dir.join("client.key"), client_key.to_pem)

    # Generate client certificate
    client_cert = OpenSSL::X509::Certificate.new
    client_cert.version = 2
    client_cert.serial = SecureRandom.random_number(2**160)
    client_cert.subject = OpenSSL::X509::Name.new([
      [ "CN", args.name, OpenSSL::ASN1::UTF8STRING ]
    ])
    client_cert.issuer = ca_cert.subject
    client_cert.public_key = client_key.public_key
    client_cert.not_before = Time.now
    client_cert.not_after = Time.now + 1.year

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = client_cert
    extension_factory.issuer_certificate = ca_cert

    client_cert.add_extension extension_factory.create_extension("basicConstraints", "CA:FALSE")
    client_cert.add_extension extension_factory.create_extension("keyUsage", "digitalSignature,keyEncipherment")
    client_cert.add_extension extension_factory.create_extension("extendedKeyUsage", "clientAuth")

    client_cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))
    File.write(client_dir.join("client.crt"), client_cert.to_pem)

    puts "Client certificate and key generated in #{client_dir}"
  end

  desc "Generate server certificate for Mosquitto"
  task create_server: :environment do
    server_dir = CERT_DIR.join("server")
    FileUtils.mkdir_p(server_dir)

    # Load CA cert and key
    ca_cert = OpenSSL::X509::Certificate.new(File.read(CERT_DIR.join("ca.crt")))
    ca_key = OpenSSL::PKey::RSA.new(File.read(CERT_DIR.join("ca.key")))

    # Generate server key
    server_key = OpenSSL::PKey::RSA.new(2048)
    File.write(server_dir.join("server.key"), server_key.to_pem)

    # Generate server certificate
    server_cert = OpenSSL::X509::Certificate.new
    server_cert.version = 2
    server_cert.serial = SecureRandom.random_number(2**160)
    server_cert.subject = OpenSSL::X509::Name.new([
      [ "CN", "mqtt.sunshine.rescoot.org", OpenSSL::ASN1::UTF8STRING ]
    ])
    server_cert.issuer = ca_cert.subject
    server_cert.public_key = server_key.public_key
    server_cert.not_before = Time.now
    server_cert.not_after = Time.now + 1.year

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = server_cert
    extension_factory.issuer_certificate = ca_cert

    server_cert.add_extension extension_factory.create_extension("basicConstraints", "CA:FALSE")
    server_cert.add_extension extension_factory.create_extension("keyUsage", "digitalSignature,keyEncipherment")
    server_cert.add_extension extension_factory.create_extension("extendedKeyUsage", "serverAuth")
    server_cert.add_extension extension_factory.create_extension("subjectAltName", "DNS:mqtt.sunshine.rescoot.org")

    server_cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))
    File.write(server_dir.join("server.crt"), server_cert.to_pem)

    puts "Server certificate and key generated in #{server_dir}"
  end

  desc "Extract public certificates for client configuration"
  task extract_public: :environment do
    public_dir = CERT_DIR.join("public")
    FileUtils.mkdir_p(public_dir)

    # CA certificate (already public)
    FileUtils.cp(CERT_DIR.join("ca.crt"), public_dir.join("ca.crt"))

    # Server certificate (already public)
    FileUtils.cp(CERT_DIR.join("server/server.crt"), public_dir.join("server.crt"))

    puts "Public certificates extracted to #{public_dir}"
    puts "These files are safe to distribute to clients:"
    puts "- ca.crt: Required to verify server and other client certificates"
    puts "- server.crt: Optional, but useful for certificate pinning"
  end
end
