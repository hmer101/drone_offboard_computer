#!/bin/bash

############################
### PRE-RUN SETUP ###
############################

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


############################
### LAUNCH REQUIRED NODES AND SCRIPTS ###
############################

# TMUX SETUP
SESSION="phys_drone"

# Kill existing session if it exists
echo "[INFO] Killing previous tmux session..."
tmux has-session -t $SESSION 2>/dev/null && tmux kill-session -t $SESSION

# Start a new tmux session detached
echo "[INFO] Launching new tmux session..."
tmux new-session -d -s $SESSION -n main

# Function to create new tmux pane and run command
tmux_pane() {
    local cmd="$1"
    tmux split-window -t ${SESSION}:0 -v "bash -ic '${cmd}; exec bash'"
    tmux select-layout -t ${SESSION}:0 tiled
}

# Start MicroXRCEAgent first
tmux_pane "MicroXRCEAgent udp4 -p 8888"

# Start ROS2 launch with drone_id_env
tmux_pane "ros2 launch highbay_vicon_px4 highbay_to_px4_manual.launch.py device_id:=${DEVICE_ID}"

# Start zenoh-bridge to recieve mocap data
tmux_pane "ros2 run zenoh_vendor zenoh-bridge-ros2dds -c /home/ws_ros2/src/zenoh_vendor/configs/zenoh_manual_drone.json5"

# Finally, attach to the session so you see it in your terminal
tmux attach-session -t $SESSION




#Need:
# Micro-XRCE-DDS-Agent: tmux_pane "MicroXRCEAgent udp4 -p 8888"
# ros: highbay_vicon_px4: tmux_pane "ros2 launch highbay_vicon_px4 highbay_to_px4_manual.launch.py device_id:={drone_id_env}"
# 
# zenoh-bridge <- optional, only if you want to use zenoh. Uses zenoh_vendor package
# To run, make sure to install, then (selecting desired configuration file):
#   ros2 run zenoh_vendor zenoh-bridge-ros2dds -c /home/ws_ros2/src/zenoh_vendor/configs/zenoh_drone.json5
