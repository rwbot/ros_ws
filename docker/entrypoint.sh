#!/bin/bash
# Basic entrypoint for ROS / Colcon Docker containers

# Source ROS
source /opt/ros/${ROS_DISTRO}/setup.bash
echo "Sourced ROS ${ROS_DISTRO}"

# Source the base workspace, if built
if [ -f /base_ws/devel/setup.bash ]
then
  echo "Tring to source base_ws"
  source /base_ws/devel/setup.bash
  echo "Sourced base_ws"
fi

# Source the overlay workspace, if built
if [ -f /overlay_ws/devel/setup.bash ]
then
  source /overlay_ws/devel/setup.bash
  echo "Sourced overlay_ws"
fi

# Execute the command passed into this entrypoint
exec "$@"
