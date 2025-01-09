##############
# ros2 foxy image #
##############
FROM foxy_dev_image AS foxy_touch_aux

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


##############
# 3DS touch drivers and OpenHaptics packages #
##############
FROM foxy_touch_aux AS foxy_touch_driver

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
FROM foxy_touch_driver AS foxy_touch_ws

ARG WS_DIR="dir_ws"
ARG USERNAME=user

ENV GTDD_HOME=/usr/share/3DSystems

USER ${USERNAME}
WORKDIR ${HOME}

# Create python wrapper folder
RUN mkdir -p $HOME/touch_py
RUN curl https://files.pythonhosted.org/packages/9f/f6/4ca6cf37a55abd0b09c6d8a15fa3b60810ea8f5f6d25fe0ac7d8438f062b/pyopenhaptics-1.0.1.tar.gz --output touch_py/pyopenhaptics-1.0.1.tar.gz && \
    cd touch_py && tar zxf pyopenhaptics-1.0.1.tar.gz

# # Create ros2 touch driver workspace folder
# RUN mkdir -p $HOME/touch_ros2_ws/src && \
#     cd $HOME/touch_ros2_ws/src && \
#     git clone https://github.com/stevens-armlab/Geomagic_Touch_ROS2

CMD /bin/bash
