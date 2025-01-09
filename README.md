Docker image for working with 3D Systems (or Geomagic) Touch haptic device using ROS2 driver OR pyOpenHaptics Python wrapper. The image is based on Ubuntu 20.04. 

* Build ROS2 foxy docker image, run the command from the `docker` folder
    ```
    userid=$(id -u) groupid=$(id -g) docker compose -f foxy_dev-compose.yml build
    ```
* Build 3D Systems Touch image that is based on the previous image:
    ```
    docker compose -f 3ds_touch_foxy-compose.yml build
    ```    
* Connect Touch haptic device (tested only with a USB model)
* Start the container:
    ```
    docker compose -f 3ds_touch_foxy-compose.yml run --rm foxy_touch_docker
    ```
* run `Touch_Setup` to initialize the device
* to start ROS2 node, see README in the `src/Geomagic_Touch_ROS2` folder
* to use python wrapper, see code examples in `~/touch_ws/pyopenhaptics-1.0.1/examples`

Used resources:
1. https://github.com/2b-t/docker-for-robotics
2. https://github.com/jhu-cisst-external/3ds-touch-openhaptics
3. https://github.com/tstoyanov/Geomagic_Touch_ROS2
4. https://support.3dsystems.com/s/article/OpenHaptics-for-Linux-Developer-Edition-v34?language=en_US