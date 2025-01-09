# Copyright (c) 2022 Ivo Dekker ACRO Diepenbeek KULeuven

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

import os
from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, RegisterEventHandler
from launch_ros.actions import Node
from launch.substitutions import Command, FindExecutable, LaunchConfiguration, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare

from launch.conditions import IfCondition
from launch.event_handlers import OnProcessExit

 
def generate_launch_description():

    # Declare arguments
    declared_arguments = []
    declared_arguments.append(
        DeclareLaunchArgument(
            "gui",
            default_value="true",
            description="Start RViz2 automatically with this launch file.",
        )
    )

    # Initialize Arguments
    gui = LaunchConfiguration("gui")

    # Get URDF via xacro
    robot_description_content = Command(
        [
            PathJoinSubstitution([FindExecutable(name="xacro")]),
            " ",
            PathJoinSubstitution(
                [
                    FindPackageShare("omni_description"),
                    "urdf",
                    "omni.urdf.xacro",
                ]
            ),
        ]
    )
    robot_description = {"robot_description": robot_description_content}
    
    rviz_config_file = PathJoinSubstitution(
        [FindPackageShare("omni_description"), "resources", "omni.rviz"]
    )

    robot_state_pub_node = Node(
        package="robot_state_publisher",
        executable="robot_state_publisher",
        output="both",
        parameters=[robot_description],
        remappings=[("joint_states", "/phantom/joint_states")],
    )
    rviz_node = Node(
        package="rviz2",
        executable="rviz2",
        name="rviz2",
        output="log",
        arguments=["-d", rviz_config_file],
        condition=IfCondition(gui),
    )
    state_pub_node = Node(
        package="omni_common",
        executable="omni_state",
        output="screen",
        parameters=[
            {"omni_name": "phantom"},
            {"publish_rate": 1000},
            {"reference_frame": "base"},
            {"units": "mm"}
        ]
    )

    nodes = [
        state_pub_node,
        robot_state_pub_node,
        rviz_node
    ]

    return LaunchDescription(declared_arguments + nodes)
