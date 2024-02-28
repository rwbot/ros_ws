# ROS distribution to use
ARG ROS_DISTRO=noetic
ARG BASE_WS=ros_ws
ARG OVERLAY_WS=overlay_ws
ARG DEV_USER=dev
########################################
# Base Image for TurtleBot3 Simulation #
########################################
# FROM osrf/ros:${ROS_DISTRO}-desktop as base
FROM ros:${ROS_DISTRO}-robot as base
ENV ROS_DISTRO=${ROS_DISTRO}
# ENV BASE_WS=base_ws
# ENV OVERLAY_WS=overlay_ws
ENV DEV_USER=${DEV_USER}
SHELL ["/bin/bash", "-c"]

# Install basic apt packages
RUN apt-get update && apt-get install -y --no-install-recommends \
 git libcanberra-gtk-module libcanberra-gtk3-module fuse3 libfuse2 libqt5svg5-dev \
 python3-pip python3-catkin-tools python3-pyqt5.qtwebengine

# Install additional Python modules
RUN pip3 install pyudev pyserial pyusb transforms3d vcstool catkin-tools

# Create Colcon workspace with external dependencies
RUN mkdir -p /base_ws/src
WORKDIR /base_ws/src
COPY dependencies.repos .
RUN vcs import < dependencies.repos

# Build the base catkin workspace, installing dependencies first.
WORKDIR /base_ws
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
 && apt-get update -y \
 && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
 && catkin build

# # Download Groot2 AppImage and place it in the home folder.
# WORKDIR /root/
# RUN curl -o Groot2.AppImage https://s3.us-west-1.amazonaws.com/download.behaviortree.dev/groot2_linux_installer/Groot2-v1.0.1-x86_64.AppImage \
#  && chmod a+x Groot2.AppImage

# Remove display warnings
RUN mkdir /tmp/runtime-root
ENV XDG_RUNTIME_DIR "/tmp/runtime-root"
RUN chmod -R 0700 /tmp/runtime-root
ENV NO_AT_BRIDGE 1

# Set up the entrypoint
WORKDIR /base_ws
COPY ./docker/entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]

###########################################
# Overlay Image for External Source Code
###########################################
FROM base AS overlay

# Create an overlay catkin workspace
RUN mkdir -p /overlay_ws/src
WORKDIR /overlay_ws
RUN echo << pwd && echo << ls
# COPY ./docking/ ./src/tb3_autonomy/
COPY ./ros_noetic_vscode/ ./src/ros_noetic_vscode/
RUN source /base_ws/devel/setup.bash \
 && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
 && catkin build

# Set up the entrypoint
COPY ./docker/entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]

#####################
# Development Image #
#####################
FROM overlay as dev

# Dev container arguments
ARG USERNAME=${DEV_USER}
ARG UID=1000
ARG GID=${UID}

# Install extra tools for development
RUN apt-get update && apt-get install -y --no-install-recommends \
 gdb gdbserver nano

# Create new user and home directory
RUN groupadd --gid $GID $USERNAME \
 && useradd --uid ${GID} --gid ${UID} --create-home ${USERNAME} \
 && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME} \
 && mkdir -p /home/${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME}

# Set the ownership of the overlay workspace to the new user
RUN chown -R ${UID}:${GID} /overlay_ws/

# Move Groot2 to new user's home directory and ensure it can be run
# RUN groupadd fuse \
#  && usermod -aG fuse ${USERNAME}
# RUN mv /root/Groot2.AppImage /home/${USERNAME} \ 
#  && chown ${UID}:${GID} /home/${USERNAME}/Groot2.AppImage

# Set the user and source entrypoint in the user's .bashrc file
USER ${USERNAME}
RUN echo "source /entrypoint.sh" >> /home/${USERNAME}/.bashrc
