FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ROS_DISTRO=jazzy \
    GZ_VERSION=harmonic \
    TURTLEBOT4_MODEL=standard \
    QT_X11_NO_MITSHM=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git gnupg locales software-properties-common sudo \
    && locale-gen en_US en_US.UTF-8 \
    && add-apt-repository -y universe \
    && rm -rf /var/lib/apt/lists/*

# Repositorios oficiales de ROS 2 y Gazebo Harmonic.
RUN set -eux; \
    ROS_APT_SOURCE_VERSION="$(curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"; \
    curl -fsSL -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.noble_all.deb"; \
    dpkg -i /tmp/ros2-apt-source.deb; \
    rm /tmp/ros2-apt-source.deb; \
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable noble main" > /etc/apt/sources.list.d/gazebo-stable.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake graphviz nano python3-colcon-common-extensions \
    python3-rosdep python3-vcstool \
    gz-harmonic \
    ros-jazzy-desktop ros-jazzy-ros-gz ros-jazzy-rosbag2 \
    ros-jazzy-rqt-graph ros-jazzy-tf2-tools \
    ros-jazzy-navigation2 ros-jazzy-nav2-bringup ros-jazzy-slam-toolbox \
    ros-jazzy-teleop-twist-keyboard \
    ros-jazzy-turtlebot4-simulator ros-jazzy-turtlebot4-navigation \
    ros-jazzy-turtlebot4-viz \
    ros-jazzy-rko-lio \
    ros-jazzy-ur ros-jazzy-ur-simulation-gz ros-jazzy-moveit \
    && rm -rf /var/lib/apt/lists/*

RUN rosdep init

ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000
RUN set -eux; \
    if getent passwd "${USER_UID}" >/dev/null; then userdel -r "$(getent passwd "${USER_UID}" | cut -d: -f1)"; fi; \
    if ! getent group "${USER_GID}" >/dev/null; then groupadd -g "${USER_GID}" "${USERNAME}"; fi; \
    useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/developer; \
    chmod 0440 /etc/sudoers.d/developer; \
    mkdir -p /home/${USERNAME}/ros2_ws/src; \
    chown -R "${USERNAME}:${USER_GID}" /home/${USERNAME}/ros2_ws

USER developer
WORKDIR /home/developer/ros2_ws
RUN echo 'source /opt/ros/jazzy/setup.bash' >> /home/developer/.bashrc \
    && echo 'if [ -f ~/ros2_ws/install/setup.bash ]; then source ~/ros2_ws/install/setup.bash; fi' >> /home/developer/.bashrc \
    && rosdep update

CMD ["bash"]
