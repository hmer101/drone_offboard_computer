#!/bin/bash

# Source the ROS setup scripts
source /opt/ros/humble/setup.bash
source /home/ws_ros2/install/setup.bash

# Create the ethernet connection file and whitelist it for ROS2 communication
#bash /home/ws_ros2/scripts_setup/create_ethernet_connection.sh # Create the ethernet connection
#bash /home/ws_ros2/scripts_setup/generate_ethernet_whitelist.sh # Create the fast_dds_config.xml file for whitelisting

# Set up chrony for time synchronization
#bash /home/ws_ros2/scripts_setup/setup_chrony.sh

# Enable loopback multicast
ip l set lo multicast on

# Conditional startup logic based on DEVICE_ROLE
# chmod +x ${BUILD_CONTEXT_ROOT}/ws_ros2/src/multi_drone_slung_load/tools/*.sh

# if [ "$DEVICE_ROLE" = "load" ]; then
#   # Command for the load device
#   #ros2 launch multi_drone_slung_load phys_load.launch.py
#   exec ${BUILD_CONTEXT_ROOT}/ws_ros2/src/multi_drone_slung_load/tools/phys_start_load.sh
# else
#   # Default command for drones
#   #ros2 launch multi_drone_slung_load phys_drone.launch.py
#   exec ${BUILD_CONTEXT_ROOT}/ws_ros2/src/multi_drone_slung_load/tools/phys_start_drone.sh
# fi

############################
### RUN THE PHYSICAL DRONE LAUNCH (this was in phys_drone.launch.py referenced above) ###
############################

# Kill existing tmux session if it exists
echo "[INFO] Killing previous tmux session..."
tmux kill-session -t phys_drone 2>/dev/null

# echo "[INFO] Launching phys_drone..."
# ros2 launch multi_drone_slung_load phys_drone.launch.py

# For now, just create a tmux session and open it in the shell
tmux new-session -d -s phys_drone

# Wait a bit to allow the launchfile to initialize tmux panes
sleep 2

# Attach to the tmux session running your physical drone launch
echo "[INFO] Attaching to the tmux session..."
exec tmux attach-session -t phys_drone
