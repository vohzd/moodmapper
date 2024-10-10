#!/bin/bash

# Exit on any error
set -e

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Ensure we're using the correct home directory
HOME_DIR=$(eval echo ~$SUDO_USER)
WORK_DIR="$HOME_DIR/dev/memorymark-2025/packages/app"

# Check if the directory exists
if [ ! -d "$WORK_DIR" ]; then
    echo "Error: Directory $WORK_DIR does not exist."
    exit 1
fi

# Change to the working directory
cd "$WORK_DIR"

# Create a certs directory if it doesn't exist
mkdir -p certs
cd certs

echo "Generating certificates in $PWD"

# Generate Root CA
openssl req -x509 -nodes -new -sha256 -days 1024 -newkey rsa:2048 -keyout memorymark-dev-RootCA.key -out memorymark-dev-RootCA.pem -subj "/C=MM/ST=MM/O=MemoryMark Dev Root CA/CN=MemoryMark Dev Root CA"

# Generate server certificate request
openssl req -new -nodes -newkey rsa:2048 -keyout memorymark-dev.key -out memorymark-dev.csr -subj "/C=MM/ST=MM/O=MemoryMark Dev/CN=memorymark-dev"

# Create domains.ext file
cat > domains.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = memorymark-dev
DNS.2 = localhost
EOF

# Generate server certificate
openssl x509 -req -sha256 -days 1024 -in memorymark-dev.csr -CA memorymark-dev-RootCA.pem -CAkey memorymark-dev-RootCA.key -CAcreateserial -extfile domains.ext -out memorymark-dev.crt

# Copy certificates to system directories
cp memorymark-dev-RootCA.pem /usr/local/share/ca-certificates/memorymark-dev-root-ca.crt
cp memorymark-dev.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Clean up temporary files
rm -f memorymark-dev.csr domains.ext
rm -f memorymark-dev-RootCA.srl 2>/dev/null || true

# Set correct permissions for the key files
chown $SUDO_USER:$SUDO_USER memorymark-dev.key memorymark-dev-RootCA.key
chmod 600 memorymark-dev.key memorymark-dev-RootCA.key

echo "Certificates generated and installed successfully."
echo "Root CA: $PWD/memorymark-dev-RootCA.pem"
echo "Server Key: $PWD/memorymark-dev.key"
echo "Server Certificate: $PWD/memorymark-dev.crt"
echo ""
echo "Next steps:"
echo "1. Update your Nuxt configuration (nuxt.config.js) with the following:"
echo ""
echo "import fs from 'fs'"
echo "import path from 'path'"
echo ""
echo "export default {"
echo "  // ... other configurations"
echo "  server: {"
echo "    https: {"
echo "      key: fs.readFileSync(path.resolve(__dirname, 'certs/memorymark-dev.key')),"
echo "      cert: fs.readFileSync(path.resolve(__dirname, 'certs/memorymark-dev.crt'))"
echo "    }"
echo "  }"
echo "}"
echo ""
echo "2. Add the following line to your /etc/hosts file:"
echo "127.0.0.1 memorymark-dev"
echo ""
echo "3. Restart your Nuxt application"
echo "4. Access your application at https://memorymark-dev:3000"

# Offer to add the entry to /etc/hosts
read -p "Would you like to add memorymark-dev to /etc/hosts now? (y/n) " add_hosts
if [ "$add_hosts" = "y" ]; then
    echo "127.0.0.1 memorymark-dev" >> /etc/hosts
    echo "Entry added to /etc/hosts."
fi

echo "Setup complete!"