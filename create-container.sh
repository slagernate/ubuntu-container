#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
  echo './create-container.sh <container name>'
  exit 1
fi

username=$(whoami)
container_name="$1"

sudo docker create --name="$container_name" \
                   --privileged \
                   -v /home/"$username"/workdir:/home/"$username"/workdir \
                   -v /dev:/dev \
                   -v /home/"$username"/.ssh:/home/"$username"/.ssh \
                   -e XDG_RUNTIME_DIR=/run/user/$(id -u) \
                   -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
                   -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY \
                   -e DISPLAY=$DISPLAY \
                   -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
                   --ipc=host \
                   --user=$(id -u):$(id -g) \
                   focal
cat <<EOF > ./enter-container.sh
#!/usr/bin/env bash
xhost +local:
sudo docker start "$container_name"
sudo docker exec --user="$username" -ite "TERM=xterm-256color" "$container_name" /bin/bash
EOF
chmod +x ./enter-container.sh
