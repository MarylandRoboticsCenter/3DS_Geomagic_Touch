##############
# modified full ubuntu image #
##############
FROM ubuntu:20.04 AS mod_ubuntu

# Set default shell
SHELL ["/bin/bash", "-c"]

WORKDIR ${HOME}

ENV DEBIAN_FRONTEND=noninteractive

# Basic setup
RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
    build-essential \
    curl \
    g++ \
    git \
    ca-certificates \
    make \
    cmake \
    automake \
    autoconf \
    bash-completion \
    iproute2 \
    iputils-ping \
    pkg-config \
    libxext-dev \
    libx11-dev \
    mc \
    mesa-utils \
    nano \
    software-properties-common \
    sudo \
    tmux \
    tzdata \
    xclip \
    x11proto-gl-dev && \
    sudo rm -rf /var/lib/apt/lists/*

# Set datetime and timezone correctly
RUN sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' | sudo tee -a /etc/timezone

ENV DEBIAN_FRONTEND=dialog

##############
# aux 3DS touch packages #
##############
FROM mod_ubuntu AS touch_aux

RUN sudo apt-get update && sudo apt-get install -y \
    freeglut3 \
    libusb-1.0-0 \
    libncurses5-dev \
    libncurses5 \
    python3-pip \
    qt5-default \
    udev \
    zlib1g-dev && \
    sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# RUN sudo /lib/systemd/systemd-udevd --daemon
# RUN udevadm monitor &

##############
# 3DS touch drivers and OpenHaptics packages #
##############
FROM touch_aux AS touch_driver

# Downloading Touch drivers and OpenHaptics packages
RUN mkdir -p temp && \
    curl https://s3.amazonaws.com/dl.3dsystems.com/binaries/Sensable/Linux/TouchDriver_2023_11_15.tgz --output temp/TouchDriver_2023_11_15.tgz && \
    curl https://s3.amazonaws.com/dl.3dsystems.com/binaries/support/downloads/KB+Files/Open+Haptics/openhaptics_3.4-0-developer-edition-amd64.tar.gz --output temp/openhaptics_3.4-0-developer-edition-amd64.tar.gz && \
    cd temp && tar xf TouchDriver_2023_11_15.tgz && \
    tar zxf openhaptics_3.4-0-developer-edition-amd64.tar.gz

# COPYING Touch drivers FILES
RUN cd temp && sudo cp TouchDriver_2023_11_15/bin/Touch* /usr/bin && \
    sudo cp TouchDriver_2023_11_15/usr/lib/libPhantomIOLib42.so /usr/lib && \
    sudo mkdir /usr/share/3DSystems && \
    sudo mkdir /usr/share/3DSystems/config && \
    sudo chmod 777 /usr/share/3DSystems/config

# COPYING Openhaptics FILES
RUN cd temp && sudo cp -R openhaptics_3.4-0-developer-edition-amd64/opt/* /opt && \
    sudo cp -R openhaptics_3.4-0-developer-edition-amd64/usr/lib/* /usr/lib && \
    sudo cp -R openhaptics_3.4-0-developer-edition-amd64/usr/include/* /usr/include && \
    sudo chmod -R 777 /opt/OpenHaptics

RUN sudo ln -sfn /usr/lib/libHD.so.3.4.0 /usr/lib/libHD.so.3.4 && \
    sudo ln -sfn /usr/lib/libHD.so.3.4.0 /usr/lib/libHD.so && \
    sudo ln -sfn /usr/lib/libHL.so.3.4.0 /usr/lib/libHL.so.3.4 && \
    sudo ln -sfn /usr/lib/libHL.so.3.4.0 /usr/lib/libHL.so && \
    sudo ln -sfn /usr/lib/libQH.so.3.4.0 /usr/lib/libQH.so.3.4 && \
    sudo ln -sfn /usr/lib/libQH.so.3.4.0 /usr/lib/libQH.so && \
    sudo ln -sfn /usr/lib/libQHGLUTWrapper.so.3.4.0 /usr/lib/libQHGLUTWrapper.so.3.4 && \
    sudo ln -sfn /usr/lib/libQHGLUTWrapper.so.3.4.0 /usr/lib/libQHGLUTWrapper.so && \
    echo "export OH_SDK_BASE=/opt/OpenHaptics/Developer/3.4-0" | sudo tee -a /etc/profile.d/openhaptics.sh

RUN rm -rf temp

RUN python3 -m pip install pyOpenHaptics && \
    python3 -m pip install pygame

##############
# user with matching uid and gid#
##############
FROM touch_driver AS touch_loc_user

ARG WS_DIR="docker_ws"
ARG USERNAME=user
ARG userid=1111
ARG groupid=1111
ARG PW=user@123

RUN groupadd -g ${groupid} -o ${USERNAME}
RUN useradd --system --create-home --home-dir /home/${USERNAME} --shell /bin/bash --uid ${userid} -g ${groupid} --groups sudo,video ${USERNAME} && \
    echo "${USERNAME}:${PW}" | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV USER=${USERNAME} \
    LANG=en_US.UTF-8 \
    HOME=/home/${USERNAME} \
    XDG_RUNTIME_DIR=/run/user/${userid} \
    TZ=America/New_York \
    GTDD_HOME=/usr/share/3DSystems

USER ${USERNAME}
WORKDIR ${HOME}

# custom Bash prompt
RUN { echo && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> .bashrc

RUN sudo mkdir -p -m 0700 /run/user/${userid} && \
    sudo chown ${USERNAME}:${USERNAME} /run/user/${userid}

# Setup tmux config
ADD --chown=${USERNAME}:${USERNAME} https://raw.githubusercontent.com/MarylandRoboticsCenter/someConfigs/refs/heads/master/.tmux_K.conf $HOME/.tmux.conf

# Create workspace folder
RUN mkdir -p $HOME/${WS_DIR}/touch_py
RUN curl https://files.pythonhosted.org/packages/9f/f6/4ca6cf37a55abd0b09c6d8a15fa3b60810ea8f5f6d25fe0ac7d8438f062b/pyopenhaptics-1.0.1.tar.gz --output ${WS_DIR}/pyopenhaptics-1.0.1.tar.gz && \
    cd ${WS_DIR} && tar zxf pyopenhaptics-1.0.1.tar.gz


CMD /bin/bash
