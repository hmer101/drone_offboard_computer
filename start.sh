#!/bin/bash

# Source the ROS setup scripts
source /opt/ros/humble/setup.bash
source /home/ws_ros2/install/setup.bash

# Create the ethernet connection file and whitelist it for ROS2 communication
#bash /home/ws_ros2/scripts_setup/create_ethernet_connection.sh # Create the ethernet connection
#bash /home/ws_ros2/scripts_setup/generate_ethernet_whitelist.sh # Create the fast_dds_config.xml file for whitelisting

# Set up chrony for time synchronization
#bash /home/ws_ros2/scripts_setup/setup_chrony.sh

# Conditional startup logic based on DEVICE_ROLE
chmod +x ${BUILD_CONTEXT_ROOT}/ws_ros2/src/multi_drone_slung_load/tools/*.sh

if [ "$DEVICE_ROLE" = "load" ]; then
  # Command for the load device
  #ros2 launch multi_drone_slung_load phys_load.launch.py
  exec ${BUILD_CONTEXT_ROOT}/ws_ros2/src/multi_drone_slung_load/tools/phys_start_load.sh
else
  # Default command for drones
  #ros2 launch multi_drone_slung_load phys_drone.launch.py
  exec ${BUILD_CONTEXT_ROOT}/ws_ros2/src/multi_drone_slung_load/tools/phys_start_drone.sh
fi
