ARG BASE_IMAGE=ros:humble-perception-jammy

# The following steps are based on the offical multi-stage build: https://github.com/IntelRealSense/librealsense/blob/master/scripts/Docker/Dockerfile
#################################
#   Librealsense Builder Stage  #
#################################
FROM $BASE_IMAGE as librealsense-builder

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -qq -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libssl-dev \
    libusb-1.0-0-dev \
    pkg-config \
    libgtk-3-dev \
    libglfw3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \    
    curl \
    python3 \
    python3-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN ln -s /usr/bin/python3 /usr/bin/python

# Get the latest tag of remote repository: https://stackoverflow.com/a/12704727
# Needs to be a single command as ENV can't be set from Bash command: https://stackoverflow.com/questions/34911622/dockerfile-set-env-to-result-of-command
RUN export LIBRS_GIT_TAG=`git -c 'versionsort.suffix=-' \
                         ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/IntelRealSense/librealsense '*.*.*' \
                         | tail --lines=1 \
                         | cut --delimiter='/' --fields=3`; \
    export LIBRS_VERSION=${LIBRS_VERSION:-${LIBRS_GIT_TAG#"v"}}; \
    curl https://codeload.github.com/IntelRealSense/librealsense/tar.gz/refs/tags/v${LIBRS_VERSION} -o librealsense.tar.gz; \
    tar -zxf librealsense.tar.gz; \
    rm librealsense.tar.gz; \
    ln -s /usr/src/librealsense-${LIBRS_VERSION} /usr/src/librealsense

RUN cd /usr/src/librealsense \
 && mkdir build && cd build \
 && cmake \
    -DCMAKE_C_FLAGS_RELEASE="${CMAKE_C_FLAGS_RELEASE} -s" \
    -DCMAKE_CXX_FLAGS_RELEASE="${CMAKE_CXX_FLAGS_RELEASE} -s" \
    -DCMAKE_INSTALL_PREFIX=/opt/librealsense \    
    -DBUILD_GRAPHICAL_EXAMPLES=OFF \
    -DBUILD_PYTHON_BINDINGS:bool=true \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DFORCE_RSUSB_BACKEND=TRUE \
    -DCMAKE_BUILD_TYPE=Release ../ \
 && make -j$(($(nproc)-1)) all \
 && make install

######################################
#   librealsense Base Image Stage    #
######################################
FROM ${BASE_IMAGE} as librealsense

COPY --from=librealsense-builder /opt/librealsense /usr/local/
COPY --from=librealsense-builder /usr/src/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
ENV PYTHONPATH=${PYTHONPATH}:/usr/local/lib


######################################
#   EVERYTHING ELSE    #
######################################


# Set a non-interactive shell to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# For pip installed packages, add the path to the PATH environment variable
ENV PATH="/root/.local/bin:$PATH" 

# Install required prerequisite packages
RUN apt-get update \ 
  && apt-get upgrade -y \
  && apt-get install -y python3 \
  && apt-get install -y python3-pip \
  && apt-get install -y curl \
  && apt-get install -y git \
  && apt-get install -y gnome-terminal \
  && apt-get install -y lsb-release \
  && apt-get install -y apt-transport-https \
  && apt-get install -y ca-certificates \
  && apt-get install -y openssh-client \
  && apt-get install -y dbus-x11 \
  && apt-get install -y libeigen3-dev \
  && apt-get install -y build-essential cmake \
  && apt-get install -y nano \
  && apt-get install -y iproute2 \
  && apt-get --reinstall install coreutils \
  && rm -rf /var/lib/apt/lists/*


# Install python packages
RUN pip install --upgrade pip

# Setup chrony
RUN apt-get update -y && \ 
    apt-get upgrade -y &&\ 
    apt-get install chrony 
    #&& \rm -rf /tmp/* /var/cache/apk/*

COPY chrony_client.conf.template /etc/chrony/chrony_client.conf
COPY chrony_server.conf.template /etc/chrony/chrony_server.conf
#EXPOSE 123/udp

# Setup for cloning repositories from GitHub
# Create a directory to hold the repositories
WORKDIR /home
RUN mkdir -p /home/repos

# Argument to pass the SSH private key
ENV SSH_PRIVATE_KEY_ENV_VAR_GH="REMOVED_PRIVATE_KEY"

# Authorize SSH Host, add the private key and start ssh-agent
RUN mkdir -p /root/.ssh && \
    echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config && \
    echo "REMOVED_PRIVATE_KEY\n"> /root/.ssh/id_ed25519 && \ 
    chmod 600 /root/.ssh/id_ed25519 && \
    eval $(ssh-agent -s) && \
    ssh-add /root/.ssh/id_ed25519


### ROS2
# Source the ROS2 setup script
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

## Setup Micro-DDS
RUN cd /home/repos && git clone https://github.com/eProsima/Micro-XRCE-DDS-Agent.git
RUN cd /home/repos/Micro-XRCE-DDS-Agent && mkdir build 
RUN cd /home/repos/Micro-XRCE-DDS-Agent/build && cmake .. && make && make install && ldconfig /usr/local/lib/ 


## Build ROS2 workspace
RUN mkdir -p /home/ws_ros2/src/  

####### Clone repos 
#-b release/drones
# release/drones_v1.15-rc2
# release/drones_v1.15-beta2
RUN cd /home/ws_ros2/src/ && \
    git clone -b release/drones git@github.com:hmer101/drone_misc.git --recursive && \
    git clone -b release/drones git@github.com:hmer101/manif.git --recursive && \
    git clone -b release/drones git@github.com:hmer101/kalmanif.git --recursive && \
    git clone -b ros2-development https://github.com/IntelRealSense/realsense-ros.git 

# Cloning finished. Remove the private GitHub key
# RUN rm -rf /root/.ssh

####### Install dependencies
RUN cd /home/ws_ros2/src/ \
 && apt-get update -y \
 && apt-get install -y ros-humble-rviz2 \
 && cd .. \
 && apt-get install -y python3-rosdep \
 && . /opt/ros/humble/setup.sh \
 && rm /etc/ros/rosdep/sources.list.d/20-default.list \
 && export GZ_VERSION=humble \
 && rosdep init \
 && rosdep update \
 && rosdep install -i --from-path src --rosdistro humble --skip-keys=librealsense2 -y


RUN cd /home/ws_ros2/src/drone_misc && \
    . /opt/ros/humble/setup.sh && \
    pip install -r requirements.txt

# WiFi extender driver
# Note: driver must be installed directly on host machine instead using:  sh -c 'wget linux.brostrend.com/install -O /tmp/install && sh /tmp/install'
# instructions here: https://linux.brostrend.com/
# RUN apt-get update && apt-get install -y wget expect \
#     && wget -qO /tmp/install http://linux.brostrend.com/install \
#     && chmod +x /tmp/install \
#     && expect -c ' \
#         spawn sh /tmp/install; \
#         expect "Please type your choice, or \\\[Enter\\\] to autodetect:" {send "c\\r"}; \
#         expect eof' \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/* /tmp/install

# Build first part of workspace
RUN cd /home/ws_ros2 && \ 
    . /opt/ros/humble/setup.sh && \
    # export CMAKE_PREFIX_PATH=/home/ws_ros2/install/kalmanif:$CMAKE_PREFIX_PATH && \
    # export CMAKE_PREFIX_PATH=/home/ws_ros2/install/manif:$CMAKE_PREFIX_PATH && \
    #. /home/ws_ros2/install/setup.sh && \
    colcon build


# Copy in sometimes changed repos
COPY ws_ros2/src/px4_msgs /home/ws_ros2/src/px4_msgs
COPY ws_ros2/src/highbay_vicon_px4 /home/ws_ros2/src/highbay_vicon_px4/

# Build second part of workspace
RUN cd /home/ws_ros2 && \ 
    . /opt/ros/humble/setup.sh && \
    colcon build --packages-select px4_msgs highbay_vicon_px4


# Copy in frequently changed repos
COPY ws_ros2/src/multi_drone_slung_load_interfaces /home/ws_ros2/src/multi_drone_slung_load_interfaces/
COPY ws_ros2/src/multi_drone_slung_load /home/ws_ros2/src/multi_drone_slung_load/
COPY ws_ros2/src/multi_drone_slung_load_cpp /home/ws_ros2/src/multi_drone_slung_load_cpp/
#COPY ws_ros2/src/slung_pose_measurement /home/ws_ros2/src/slung_pose_measurement/
#COPY ws_ros2/src/slung_pose_estimation /home/ws_ros2/src/slung_pose_estimation/

# Build remaining parts of colcon workspace
# Make frame transforms .so
RUN cd /home/ws_ros2/src/multi_drone_slung_load/multi_drone_slung_load/frame_transforms && \
    . /opt/ros/humble/setup.sh && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make && \
    cp frame_transforms.cpython-310-x86_64-linux-gnu.so ../../frame_transforms.so
    
# NUC: cp frame_transforms.cpython-310-x86_64-linux-gnu.so ../../frame_transforms.so
# RPI: cp frame_transforms.cpython-310-aarch64-linux-gnu.so ../../frame_transforms.so

RUN cd /home/ws_ros2 && \ 
    . /opt/ros/humble/setup.sh && \
    colcon build --packages-select  multi_drone_slung_load_interfaces multi_drone_slung_load multi_drone_slung_load_cpp

# manif kalmanif slung_pose_measurement slung_pose_estimation 


# TODO: MOVE UP DOCKERFILE
RUN apt-get update -y && \ 
    apt-get upgrade -y &&\ 
    apt-get install -y ros-humble-rmw-cyclonedds-cpp

COPY ./cyclone_dds_config.xml /home/ws_ros2/cyclone_dds_config.xml

# Source the ROS2 overlay workspace
RUN echo "source /home/ws_ros2/install/setup.bash" >> ~/.bashrc

# Copy the startup scripts
COPY scripts_setup /home/ws_ros2/scripts_setup
COPY start.sh /home/ws_ros2/start.sh

# Use the script as the entry point
CMD ["/home/ws_ros2/start.sh"]

### COMMANDS 
# Building this dockerfile with ARGS
# docker build --build-arg SSH_PRIVATE_KEY="$(cat /home/harvey/.ssh/id_ed25519)" -f dockerfile_drone -t drone:first . #--no-cache
# When deploying in Balena, use in ENV variable for SSH_PRIVATE_KEY_ENV_VAR_GH instead

# Running dockerfile interactively (useful if using CMD ["bash"])
# docker run --tty -it drone:first

# GUI Forwarding: docker run --tty -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:ro -it drone:first
# Need to run "xhost +" on host machine first

# Building with balena: balena push slung_load_x500
