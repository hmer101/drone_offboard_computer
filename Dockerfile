FROM arm64v8/ubuntu:22.04 
#as base

# Set a non-interactive shell to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# For pip installed packages, add the path to the PATH environment variable
ENV PATH="/root/.local/bin:$PATH" 

# Install required prerequisite packages
RUN apt-get update \ 
  && apt-get upgrade -y \
  && apt-get install -y python3 \
  && apt-get install -y python3-pip \
  && apt-get install -y git \
  && apt-get install -y lsb-release \
  && apt-get install -y openssh-client \
  && apt-get install -y gnome-terminal \ 
  && apt-get install -y dbus-x11 \
  && apt-get install -y libeigen3-dev \
  && apt-get install -y build-essential cmake \
  && apt-get install -y nano \
  && apt-get install -y iproute2 \
  && rm -rf /var/lib/apt/lists/*

#ros-humble-ros-gz

# Install python packages
RUN pip install --upgrade pip

# Install sudo, lsb-release, wget, and other necessary tools for PX4
#RUN apt-get update && apt-get install -y sudo lsb-release wget dmidecode libeigen3-dev libopencv-dev libxml2-utils pkg-config protobuf-compiler gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav libgstreamer-plugins-base1.0-dev libimage-exiftool-perl


# Setup for cloning repositories from GitHub
# Create a directory to hold the repositories
WORKDIR /home
RUN mkdir -p /home/repos

# Argument to pass the SSH private key
ENV SSH_PRIVATE_KEY_ENV_VAR_GH="b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW\nQyNTUxOQAAACD7gB7FKLkuqZmMXROIUri8EwLXEu0cf+mrIjzeBauY8QAAAJib05lGm9OZ\nRgAAAAtzc2gtZWQyNTUxOQAAACD7gB7FKLkuqZmMXROIUri8EwLXEu0cf+mrIjzeBauY8Q\nAAAEDVYapfTsF/wTb0I64xw6O9a/J3oSRc9MJW3AZM8LCrb/uAHsUouS6pmYxdE4hSuLwT\nAtcS7Rx/6asiPN4Fq5jxAAAAD2htZXIxMDFAbWl0LmVkdQECAwQFBg=="

# Authorize SSH Host, add the private key and start ssh-agent
RUN mkdir -p /root/.ssh && \
    echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config && \
    echo "-----BEGIN OPENSSH PRIVATE KEY-----\n$SSH_PRIVATE_KEY_ENV_VAR_GH\n-----END OPENSSH PRIVATE KEY-----\n"> /root/.ssh/id_ed25519 && \ 
    chmod 600 /root/.ssh/id_ed25519 && \
    eval $(ssh-agent -s) && \
    ssh-add /root/.ssh/id_ed25519


## PX4
#FROM base as px4-setup
# Setup PX4
#RUN cd /home/repos && git clone -b release/drones git@github.com:hmer101/PX4-Autopilot.git --recursive

#RUN chmod +x ./repos/PX4-Autopilot/Tools/setup/ubuntu.sh
#RUN bash ./repos/PX4-Autopilot/Tools/setup/ubuntu.sh

# Build PX4
#RUN cd /home/repos/PX4-Autopilot && make px4_sitl


## Install ROS2
#FROM px4-setup as ros2-install
#FROM base as ros2-install
# Install locales and set en_US.UTF-8
RUN apt-get update && \
    apt-get install -y locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install necessary packages
RUN apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y curl

# Add the ROS2 repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Update and install ROS2
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ros-humble-desktop

# Install additional ROS development tools
RUN apt-get install -y ros-dev-tools

# Source the ROS2 setup script
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc


## Setup Micro-DDS
RUN cd /home/repos && git clone https://github.com/eProsima/Micro-XRCE-DDS-Agent.git
RUN cd /home/repos/Micro-XRCE-DDS-Agent && mkdir build 
RUN cd /home/repos/Micro-XRCE-DDS-Agent/build && cmake .. && make && make install && ldconfig /usr/local/lib/ 


## Build ROS2 workspace
RUN mkdir -p /home/ws_ros2/src/  

#FROM ros2-install as ros2-ws-deps
# Clone repos
RUN cd /home/ws_ros2/src/ && \
    git clone -b release/drones git@github.com:hmer101/px4_msgs.git --recursive && \
    git clone -b release/drones git@github.com:hmer101/drone_misc.git --recursive

    #&& \
    #git clone -b release/v1.14 https://github.com/PX4/px4_ros_com.git --recursive && \ 
    #git clone -b humble https://github.com/gazebosim/ros_gz.git --recursive && \
    #git clone https://github.com/artivis/manif.git --recursive && \
    #git clone https://github.com/artivis/kalmanif.git --recursive && \

    #git clone -b release/drones git@github.com:hmer101/slung_pose_estimation.git --recursive #&& \
    #git clone -b release/drones git@github.com:hmer101/swarm_load_carry.git --recursive && \
    #git clone -b release/drones git@github.com:hmer101/swarm_load_carry_interfaces.git --recursive 

# Cloning finished. Remove the private GitHub key
# RUN rm -rf /root/.ssh

# Install dependencies
RUN cd /home/ws_ros2 && \
    . /opt/ros/humble/setup.sh && \
    export GZ_VERSION=humble && \
    rosdep init && \
    rosdep update && \
    rosdep install -r --from-paths src -i -y --rosdistro humble

RUN cd /home/ws_ros2/src/drone_misc && \
    . /opt/ros/humble/setup.sh && \
    pip install -r requirements_drones.txt

RUN pip uninstall -y em
RUN pip install --user -U empy==3.3.4 pyros-genmsg setuptools

# Build first part of workspace
RUN cd /home/ws_ros2 && \ 
    . /opt/ros/humble/setup.sh && \
    # export CMAKE_PREFIX_PATH=/home/ws_ros2/install/kalmanif:$CMAKE_PREFIX_PATH && \
    # export CMAKE_PREFIX_PATH=/home/ws_ros2/install/manif:$CMAKE_PREFIX_PATH && \
    #. /home/ws_ros2/install/setup.sh && \
    colcon build


# Copy in frequently changed repos
#FROM ros2-ws-deps as ros2-ws-copy
COPY ws_ros2/src/swarm_load_carry /home/ws_ros2/src/swarm_load_carry/
COPY ws_ros2/src/swarm_load_carry_interfaces /home/ws_ros2/src/swarm_load_carry_interfaces/
#--from=ros2-ws-deps


# Build remaining parts of colcon workspace
#FROM ros2-ws-copy as ros2-ws-build
# Make frame transforms .so
RUN cd /home/ws_ros2/src/swarm_load_carry/swarm_load_carry/frame_transforms && \
    . /opt/ros/humble/setup.sh && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make && \
    cp frame_transforms.cpython-310-aarch64-linux-gnu.so ../../frame_transforms.so

RUN cd /home/ws_ros2 && \ 
    . /opt/ros/humble/setup.sh && \
    colcon build --packages-select swarm_load_carry_interfaces swarm_load_carry 


# Install realsense camera software
RUN mkdir -p /etc/apt/keyrings && \ 
    curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null && \
    apt-get install -y apt-transport-https && \
    echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | \ tee /etc/apt/sources.list.d/librealsense.list && \
    apt-get update && \
    apt-get install -y librealsense2-dkms && \
    apt-get install -y librealsense2-utils && \
    apt-get install -y librealsense2-dev && \
    apt-get install -y librealsense2-dbg


RUN cd /home/ws_ros2 && \ 
    . /opt/ros/humble/setup.sh && \
    apt install -y ros-humble-realsense2-*


# Source the ROS2 overlay workspace
RUN echo "source /home/ws_ros2/install/setup.bash" >> ~/.bashrc

# Set the entrypoint or command, depending on your use case
CMD ["/bin/bash", "-c", "source /opt/ros/humble/setup.bash && source /home/ws_ros2/install/setup.bash && ros2 launch swarm_load_carry phys_drone.launch.py"]


### COMMANDS 
# Building this dockerfile with ARGS
# docker build --build-arg SSH_PRIVATE_KEY="$(cat /home/harvey/.ssh/id_ed25519)" -f dockerfile_drone -t drone:first . #--no-cache
# When deploying in Balena, use in ENV variable for SSH_PRIVATE_KEY_ENV_VAR_GH instead

# Running dockerfile interactively (useful if using CMD ["bash"])
# docker run --tty -it drone:first

# GUI Forwarding: docker run --tty -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:ro -it drone:first
# Need to run "xhost +" on host machine first

# Building with balena: balena push slung_load_x500
