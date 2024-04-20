#!/bin/bash

# Source the ROS setup scripts
source /opt/ros/humble/setup.bash
source /home/ws_ros2/install/setup.bash

# Create the ethernet connection file and whitelist it for ROS2 communication
bash /home/ws_ros2/scripts_setup/create_ethernet_connection.sh # Create the ethernet connection
bash /home/ws_ros2/scripts_setup/generate_ethernet_whitelist.sh # Create the fast_dds_config.xml file for whitelisting

# Conditional startup logic based on DEVICE_ROLE
if [ "$DEVICE_ROLE" = "load" ]; then
  # Command for the load device
  ros2 launch swarm_load_carry phys_load.launch.py
else
  # Default command for drones
  ros2 launch swarm_load_carry phys_drone.launch.py
fi
