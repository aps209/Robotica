#!/usr/bin/env python3
"""Envía una meta 2D a Nav2 desde la consola."""
import argparse
import math
import sys

import rclpy
from action_msgs.msg import GoalStatus
from nav2_msgs.action import NavigateToPose
from rclpy.action import ActionClient
from rclpy.node import Node


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('x', type=float, help='Coordenada x en el marco map (m)')
    parser.add_argument('y', type=float, help='Coordenada y en el marco map (m)')
    parser.add_argument('yaw', type=float, help='Orientación en radianes')
    args = parser.parse_args()

    rclpy.init()
    node = Node('cliente_nav_practica')
    try:
        client = ActionClient(node, NavigateToPose, 'navigate_to_pose')
        if not client.wait_for_server(timeout_sec=20.0):
            raise RuntimeError('Nav2 no ofrece /navigate_to_pose. Revisa los nodos lifecycle.')

        goal = NavigateToPose.Goal()
        goal.pose.header.frame_id = 'map'
        goal.pose.header.stamp = node.get_clock().now().to_msg()
        goal.pose.pose.position.x = args.x
        goal.pose.pose.position.y = args.y
        goal.pose.pose.orientation.z = math.sin(args.yaw / 2.0)
        goal.pose.pose.orientation.w = math.cos(args.yaw / 2.0)

        future = client.send_goal_async(goal)
        rclpy.spin_until_future_complete(node, future)
        handle = future.result()
        if not handle.accepted:
            raise RuntimeError('Nav2 rechazó la meta.')
        print('Meta aceptada; esperando a que termine la navegación...')
        result_future = handle.get_result_async()
        rclpy.spin_until_future_complete(node, result_future)
        status = result_future.result().status
        if status != GoalStatus.STATUS_SUCCEEDED:
            raise RuntimeError(f'Navegación terminada con estado {status}.')
        print('Meta alcanzada.')
    except (RuntimeError, KeyboardInterrupt) as exc:
        print(exc, file=sys.stderr)
        return 1
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()
    return 0


if __name__ == '__main__':
    sys.exit(main())
