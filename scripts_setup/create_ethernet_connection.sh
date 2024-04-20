#!/bin/bash

# Ensure the IP_ADDR_ETH environment variable is set
if [ -z "$IP_ADDR_ETH" ]; then
  echo "Error: IP_ADDR_ETH environment variable is not set."
  exit 1
fi

# Path to the directory where the file will be saved
CONFIG_DIR='./test' #"/mnt/boot/system-connections"

# Check if the directory exists, create it if it doesn't
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Directory $CONFIG_DIR does not exist. Creating directory."
  mkdir -p "$CONFIG_DIR"
fi

# Path to the configuration file
CONFIG_FILE="${CONFIG_DIR}/Ethernet"

# Create or overwrite the configuration file
cat > "$CONFIG_FILE" <<EOF
[connection]
id=my-ethernet
type=ethernet
interface-name=eth0
permissions=
secondaries=

[ethernet]
mac-address-blacklist=

[ipv4]
address1=${IP_ADDR_ETH}/24,192.168.0.1
dns=8.8.8.8;8.8.4.4;
dns-search=
method=manual

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
method=auto
EOF

echo "Network configuration file created: $CONFIG_FILE"
