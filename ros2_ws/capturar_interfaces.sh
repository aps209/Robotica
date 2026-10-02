#!/usr/bin/env bash
# Uso: bash capturar_interfaces.sh bloque2_slam|bloque2_nav|bloque3|bloque4
set -euo pipefail
source /opt/ros/jazzy/setup.bash

etapa="${1:?Indica bloque2_slam, bloque2_nav, bloque3 o bloque4}"
case "$etapa" in
  bloque2_slam|bloque2_nav|bloque3|bloque4) ;;
  *) echo "Etapa desconocida: $etapa" >&2; exit 2 ;;
esac

dest="/home/developer/ros2_ws/evidencias/$etapa"
mkdir -p "$dest/nodos"
cd "$dest"
date -Is > fecha.txt
ros2 node list --all > nodos.txt
ros2 topic list -t > topicos.txt
ros2 service list -t > servicios.txt
ros2 action list -t > acciones.txt
ros2 param list > parametros.txt

while IFS= read -r nodo; do
  nombre="$(printf '%s' "$nodo" | sed 's#[^[:alnum:]_-]#_#g')"
  ros2 node info "$nodo" > "nodos/${nombre}.txt" || true
done < nodos.txt

for topico in /scan /map /odom /imu /points /tf /tf_static /joint_states /cmd_vel; do
  if ros2 topic list | grep -Fxq "$topico"; then
    nombre="${topico#/}"
    ros2 topic info -v "$topico" > "topico_${nombre}.txt" || true
  fi
done

timeout 20s ros2 run tf2_tools view_frames > view_frames.log 2>&1 || true
timeout 5s ros2 topic echo /tf --once > tf_ejemplo.txt 2>&1 || true
if [ ! -f frames.pdf ]; then
  echo "No se generó frames.pdf; revisa view_frames.log y si hay TF activo." >&2
fi
echo "Datos guardados en $dest. Guarda una captura de rqt_graph como grafo.png."
