#!/usr/bin/env python3
"""Envía una pose cartesiana al grupo ur_manipulator mediante MoveGroup."""
import argparse
import math
import sys

import rclpy
from geometry_msgs.msg import Pose
from moveit_msgs.action import MoveGroup
from moveit_msgs.msg import Constraints, MoveItErrorCodes, OrientationConstraint, PositionConstraint
from rclpy.action import ActionClient
from rclpy.node import Node
from shape_msgs.msg import SolidPrimitive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('x', 'y', 'z', 'qx', 'qy', 'qz', 'qw'):
        parser.add_argument(name, type=float)
    parser.add_argument('--frame', default='base_link', help='Marco de la pose (base_link por defecto)')
    parser.add_argument('--link', default='tool0', help='Eslabón final (tool0 por defecto)')
    parser.add_argument('--plan-only', action='store_true', help='Solo planifica, sin ejecutar')
    args = parser.parse_args()

    norm = math.sqrt(args.qx**2 + args.qy**2 + args.qz**2 + args.qw**2)
    if not math.isfinite(norm) or norm < 1e-9:
        parser.error('El cuaternión debe tener norma no nula y valores finitos.')
    if not all(math.isfinite(v) for v in (args.x, args.y, args.z)):
        parser.error('La posición debe contener valores finitos.')

    rclpy.init()
    node = Node('cliente_ur_practica')
    try:
        client = ActionClient(node, MoveGroup, 'move_action')
        if not client.wait_for_server(timeout_sec=30.0):
            raise RuntimeError('MoveIt no ofrece /move_action. Comprueba move_group.')

        pose = Pose()
        pose.position.x, pose.position.y, pose.position.z = args.x, args.y, args.z
        pose.orientation.x, pose.orientation.y = args.qx / norm, args.qy / norm
        pose.orientation.z, pose.orientation.w = args.qz / norm, args.qw / norm

        position = PositionConstraint()
        position.header.frame_id = args.frame
        position.link_name = args.link
        position.weight = 1.0
        sphere = SolidPrimitive()
        sphere.type = SolidPrimitive.SPHERE
        sphere.dimensions = [0.01]  # tolerancia espacial de 1 cm
        position.constraint_region.primitives = [sphere]
        position.constraint_region.primitive_poses = [pose]

        orientation = OrientationConstraint()
        orientation.header.frame_id = args.frame
        orientation.link_name = args.link
        orientation.orientation = pose.orientation
        orientation.absolute_x_axis_tolerance = 0.1
        orientation.absolute_y_axis_tolerance = 0.1
        orientation.absolute_z_axis_tolerance = 0.1
        orientation.weight = 1.0

        constraints = Constraints()
        constraints.position_constraints = [position]
        constraints.orientation_constraints = [orientation]

        goal = MoveGroup.Goal()
        goal.request.group_name = 'ur_manipulator'
        goal.request.num_planning_attempts = 10
        goal.request.allowed_planning_time = 10.0
        goal.request.max_velocity_scaling_factor = 0.2
        goal.request.max_acceleration_scaling_factor = 0.2
        goal.request.start_state.is_diff = True  # estado actual del robot
        goal.request.goal_constraints = [constraints]
        goal.planning_options.plan_only = args.plan_only

        future = client.send_goal_async(goal)
        rclpy.spin_until_future_complete(node, future)
        handle = future.result()
        if not handle.accepted:
            raise RuntimeError('MoveIt rechazó la meta.')
        print('Meta aceptada; esperando resultado...')
        result_future = handle.get_result_async()
        rclpy.spin_until_future_complete(node, result_future)
        result = result_future.result().result
        if result.error_code.val != MoveItErrorCodes.SUCCESS:
            raise RuntimeError(f'MoveIt devolvió código {result.error_code.val}.')
        print('Plan calculado.' if args.plan_only else 'Trayectoria ejecutada.')
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
