#!/bin/sh

## CHECK THAT THE CORRECT ENVIRONMENT VARIABLES ARE SET
# Check if the FIRST_DRONE_ID environment variable is set
# Check that IP_ADDR_CHRN is set
if [ -z "$IP_ADDR_CHRN" ]; then
  echo "The IP_ADDR_CHRN environment variable is not set."
  exit 1
fi

if [ -z "$FIRST_DRONE_ID" ]; then
  echo "The FIRST_DRONE_ID environment variable is not set."
  exit 1
fi

# Check if DEVICE_ROLE is set
if [ -z "$DEVICE_ROLE" ]; then
  echo "The DEVICE_ROLE environment variable is not set."
  exit 1
fi

# If DEVICE_ROLE is 'drone', check if DRONE_ID is set
if [ "$DEVICE_ROLE" = "drone" ] && [ -z "$DRONE_ID" ]; then
  echo "The DRONE_ID environment variable must be set when DEVICE_ROLE is 'drone'."
  exit 1
fi


## SETUP CHRONY
# Start the chrony server on the first drone and client on all other devices

if [ "$DEVICE_ROLE" = "drone" ] && [ "$DRONE_ID" = "$FIRST_DRONE_ID" ]; then
    cp -f /etc/chrony/chrony_server.conf /etc/chrony/chrony.conf
    echo "" >> /etc/chrony/chrony.conf
    echo "allow $IP_ADDR_CHRN/24" >> /etc/chrony/chrony.conf

else
    cp -f /etc/chrony/chrony_client.conf /etc/chrony/chrony.conf
    echo "" >> /etc/chrony/chrony.conf
    echo "server $IP_ADDR_CHRN iburst minpoll 1 maxpoll 2" >> /etc/chrony/chrony.conf
fi

# Start chronyd 
#chronyd -F -d in the foreground
rm -f /var/run/chrony/chronyd.pid
/usr/sbin/chronyd -d & #-x

echo "Chrony set up complete. Chrony started"