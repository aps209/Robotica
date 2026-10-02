# Práctica I: lo que queda por hacer

El entorno está definido en `Dockerfile`, se inicia con `iniciar.cmd` y conserva los datos en `ros2_ws`. La memoria compilada está en `memoria/memoria.pdf`. Sus recuadros «Pendiente de evidencia experimental» indican datos que hay que observar de verdad antes de entregar. El PDF no sustituye la demostración presencial ni las preguntas individuales del guion.

## 0. Puesta en marcha en este PC Windows

1. Arranca Docker Desktop. El script abre VcXsrv en la pantalla `:0` para las ventanas Linux. Si Windows pide permiso de cortafuegos, permite la red privada. El arranque usa `DISPLAY=host.docker.internal:0.0` y renderizado por software, así que Gazebo puede ir lento.
2. En PowerShell, desde esta carpeta, ejecuta `./iniciar.cmd`. Con `./iniciar.cmd -Build -Recreate` se reconstruye la imagen y sustituye el contenedor si cambia el Dockerfile; los archivos de `ros2_ws` se conservan. La primera construcción descarga varios gigabytes.
3. Cada terminal adicional se abre con `docker exec -it robotica_inteligente_grado bash`. En terminales nuevas, comprueba `ros2 --help`, `ros2 pkg prefix turtlebot4_gz_bringup`, `ros2 pkg prefix rko_lio` y `ros2 pkg prefix ur_simulation_gz`.
4. Haz una prueba de ventanas con `rviz2`. Si aparece «cannot connect to display», revisa XLaunch y el cortafuegos. La carpeta del host `ros2_ws` corresponde a `/home/developer/ros2_ws` dentro del contenedor.

## 1. Fundamentos ROS 2

1. Completa los tutoriales **Beginner** y **Tf2** de [ROS 2 Jazzy](https://docs.ros.org/en/jazzy/Tutorials.html). Explica en voz alta la diferencia entre nodo, tópico, servicio, acción, parámetro y transformación.
2. Practica con `ros2 run demo_nodes_cpp talker` en una terminal y `ros2 run demo_nodes_cpp listener` en otra. Inspecciona `ros2 node list`, `ros2 topic list -t`, `ros2 topic echo /chatter`, `ros2 node info /talker` y `ros2 run rqt_graph rqt_graph`.

## 2. TurtleBot 4: mapa y navegación

Usa **un comando por terminal**. Mantén el simulador activo durante ambas fases. Al pasar a la fase B, cierra el proceso de SLAM y el RViz anterior; reutiliza Gazebo sin lanzar una segunda instancia.

### Fase A: SLAM

```bash
# Terminal 1
ros2 launch turtlebot4_gz_bringup turtlebot4_gz.launch.py
# Terminal 2
ros2 launch turtlebot4_navigation slam.launch.py use_sim_time:=true
# Terminal 3
ros2 launch turtlebot4_viz view_navigation.launch.py use_sim_time:=true
```

1. Conduce el robot desde la pestaña **keyboard** de Gazebo hasta cubrir pasillos y obstáculos. Comprueba que el mapa crece en RViz.
2. Guarda el mapa desde otra terminal: `ros2 run nav2_map_server map_saver_cli -f /home/developer/ros2_ws/mapa_laboratorio`. Verifica que aparecen `.pgm` y `.yaml`.
3. Mientras siguen activos los nodos, ejecuta `bash capturar_interfaces.sh bloque2_slam`; después abre `ros2 run rqt_graph rqt_graph` y guarda la captura como `evidencias/bloque2_slam/grafo.png`.

### Fase B: navegación

```bash
# Terminal 1: sigue activo el simulador de la fase A.
# Si lo cerraste, relánzalo con:
ros2 launch turtlebot4_gz_bringup turtlebot4_gz.launch.py
# Terminal 2
ros2 launch turtlebot4_navigation localization.launch.py map:=/home/developer/ros2_ws/mapa_laboratorio.yaml use_sim_time:=true
# Terminal 3
ros2 launch turtlebot4_navigation nav2.launch.py use_sim_time:=true
# Terminal 4
ros2 launch turtlebot4_viz view_navigation.launch.py use_sim_time:=true
```

1. En RViz marca **2D Pose Estimate** sobre la posición real y orientación del robot. Espera a que AMCL converja y aparezcan los mapas de coste.
2. En un lugar libre marca **2D Goal Pose**. Observa ruta, evasión de obstáculos y llegada. Alternativamente prueba el script opcional: `python3 enviar_meta_nav.py X Y YAW`, con metros y radianes en el marco `map`.
3. Ejecuta `bash capturar_interfaces.sh bloque2_nav`, guarda `evidencias/bloque2_nav/grafo.png` desde rqt\_graph y documenta el resultado real en la memoria.

## 3. RKO-LIO con Oxford Spires

1. Descarga del [enlace de materiales del guion](https://drive.google.com/drive/folders/1LaoKVN74P8LwPM8vF6ZdRd_l6eM6QsAc?usp=drive_link) la carpeta `1710255615_2024-03-12-15-00-16` y `oxford_spires.yaml`. Pon ambos dentro de `ros2_ws`. Comprueba que el bag contiene `metadata.yaml` con `ros2 bag info 1710255615_2024-03-12-15-00-16`.
2. Lanza en una terminal `python3 lanzar_rko.py oxford_spires.yaml`. El script usa el lanzador oficial y configura `use_sim_time` para RKO-LIO y RViz; el argumento `use_sim_time:=true` que aparece en el guion no está declarado por la versión instalada del lanzador.
3. En otra, desde `/home/developer/ros2_ws`, ejecuta `ros2 bag play 1710255615_2024-03-12-15-00-16/ --clock`.
4. Durante la reproducción ejecuta `bash capturar_interfaces.sh bloque3`, guarda `evidencias/bloque3/grafo.png` y una captura de RViz como `resultado.png`. Anota avisos, tiempo procesado, tópicos reales y calidad visual de la reconstrucción.

## 4. UR3e con MoveIt 2

1. Lanza `ros2 launch ur_simulation_gz ur_sim_moveit.launch.py ur_type:=ur3e`. Este lanzador ya configura internamente `use_sim_time:=true`.
2. En RViz mueve el marcador del extremo a una pose alcanzable. Pulsa **Plan and Execute** y comprueba que el brazo se mueve también en Gazebo. Prueba una pose inalcanzable y registra el error.
3. Ejecuta `bash capturar_interfaces.sh bloque4`, guarda `evidencias/bloque4/grafo.png` y `resultado.png`.
4. Prueba el script opcional: `python3 enviar_pose_ur.py X Y Z QX QY QZ QW --plan-only`. Los valores son una pose de `tool0` en `base_link`; el cuaternión se normaliza automáticamente. Cuando una pose segura haya planificado correctamente, repite sin `--plan-only` para ejecutarla.

## 5. Cerrar la memoria y preparar la defensa

1. Abre `memoria/memoria.tex`; rellena integrantes y todos los recuadros con tus observaciones. Comprueba especialmente los nombres de nodos y tópicos, los servicios y acciones, el flujo de información, y quién publica cada transformación TF. Las tablas actuales son una **hipótesis técnica**, no el resultado observado.
2. Compila desde la carpeta `memoria`: `xelatex -interaction=nonstopmode -halt-on-error memoria.tex` dos veces. Revisa `memoria.pdf` y entrega **ese PDF**.
3. Para la evaluación presencial mantén abierto el contenedor y el bloque correspondiente. Cada integrante debe poder explicar por qué `map→odom→base_link` cambia en navegación, cómo se usa `/clock` con el bag y cómo una meta cartesiana se convierte en una trayectoria articular.

## Notas de funcionamiento

- El guion supone un anfitrión Ubuntu con X11 y GPU NVIDIA. Este equipo usa Windows/Docker Desktop; el arranque incluido usa X11 por TCP y renderizado por CPU. No se ha supuesto que `--network host`, `/dev/dri` o `--gpus all` funcionen en este host.
- El script `capturar_interfaces.sh` guarda un `frames.pdf` y listados ROS en cada etapa. La captura de rqt\_graph y la explicación del grafo requieren interacción en pantalla.
- El dataset del bloque 3 no está en esta carpeta de partida; su descarga y sus resultados experimentales quedan por hacer.
