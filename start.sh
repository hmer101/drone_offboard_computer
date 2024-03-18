#!/bin/bash

# Source the ROS setup scripts
source /opt/ros/humble/setup.bash
source /home/ws_ros2/install/setup.bash

# Conditional startup logic based on DEVICE_ROLE
if [ "$DEVICE_ROLE" = "load" ]; then
  # Command for the load device
  ros2 launch swarm_load_carry phys_load.launch.py
else
  # Default command for drones
  ros2 launch swarm_load_carry phys_drone.launch.py
fi