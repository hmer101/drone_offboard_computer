#!/bin/bash

# Check if the IP_ADDR_ETH environment variable is set
if [ -z "$IP_ADDR_ETH" ]; then
  echo "The IP_ADDR_ETH environment variable is not set."
  exit 1
fi


# Create the XML configuration file
cat <<EOF > /home/ws_ros2/fast_dds_config.xml
<?xml version="1.0" encoding="UTF-8" ?>
<dds xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">
    <profiles>
        <transport_descriptors>
            <transport_descriptor>
                <transport_id>CustomUdpTransport</transport_id>
                <type>UDPv4</type>
                <interfaceWhiteList>
                    <address>${IP_ADDR_ETH}</address>
                </interfaceWhiteList>
            </transport_descriptor>
        </transport_descriptors>

        <participant profile_name="CustomTcpTransportParticipant" is_default_profile="true">
            <rtps>
                <userTransports>
                    <transport_id>CustomUdpTransport</transport_id>
                </userTransports>
                <useBuiltinTransports>false</useBuiltinTransports>
            </rtps>
        </participant>
    </profiles>
</dds>
EOF

echo "Created the DDS ethernet whitelist"
