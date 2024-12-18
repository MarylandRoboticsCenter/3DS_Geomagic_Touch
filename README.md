Docker image for working with 3D Systems Touch haptic device and pyOpenHaptics Python wrapper. The image is based on Ubuntu 20.04. 

* Build the image:
    ```
    userid=$(id -u) groupid=$(id -g) docker compose -f 3ds_touch-compose.yml build
    ```
* Connect Touch haptic device (tested only with a USB model)
* Start the container:
    ```
    docker compose -f 3ds_touch-compose.yml run --rm 3ds_touch_docker
    ```
* run `Touch_Setup` to initialize the device
* see examples of using the python wrapper in `~/touch_ws/pyopenhaptics-1.0.1/examples`

Used resources:
1. https://github.com/2b-t/docker-for-robotics
2. https://github.com/jhu-cisst-external/3ds-touch-openhaptics
3. https://support.3dsystems.com/s/article/OpenHaptics-for-Linux-Developer-Edition-v34?language=en_US