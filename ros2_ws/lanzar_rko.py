#!/usr/bin/env python3
"""Lanza RKO-LIO y RViz con reloj de simulación para reproducir un rosbag."""
import argparse
import sys
from pathlib import Path

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription, LaunchService
from launch.actions import GroupAction, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import SetParameter


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('config_file', type=Path, help='YAML entregado con Oxford Spires')
    args = parser.parse_args()
    config = args.config_file.expanduser().resolve()
    if not config.is_file():
        parser.error(f'No existe el archivo {config}')

    original = Path(get_package_share_directory('rko_lio')) / 'launch' / 'odometry.launch.py'
    description = LaunchDescription([
        GroupAction(actions=[
            SetParameter(name='use_sim_time', value=True),
            IncludeLaunchDescription(
                PythonLaunchDescriptionSource(str(original)),
                launch_arguments={
                    'initialization_phase': 'false',
                    'rviz': 'true',
                    'config_file': str(config),
                }.items(),
            ),
        ]),
    ])
    service = LaunchService()
    service.include_launch_description(description)
    return service.run()


if __name__ == '__main__':
    sys.exit(main())
