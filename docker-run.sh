#!/usr/bin/env bash
# Launch the g-code-utils GUI container on the host X server (X11 or XWayland).
set -euo pipefail

IMAGE="${IMAGE:-g-code-utils}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/g-code-utils"
mkdir -p "$CONFIG_DIR"

: "${DISPLAY:?DISPLAY is not set - is an X server / XWayland running?}"

args=(
  --rm
  --name g-code-utils
  --user "$(id -u):$(id -g)"
  -e DISPLAY
  -e HOME="$HOME"
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro
  # Host home at the same path so file dialogs can open/save G-code anywhere in it
  -v "$HOME:$HOME"
  # settings.config is written to the working directory
  -v "$CONFIG_DIR:/data"
  # JavaFX uses shared memory for X rendering
  --ipc=host
)

# KDE/XWayland put the X cookie in a non-default location ($XAUTHORITY)
if [[ -n "${XAUTHORITY:-}" && -f "$XAUTHORITY" ]]; then
  args+=(-e XAUTHORITY=/tmp/.Xauthority -v "$XAUTHORITY:/tmp/.Xauthority:ro")
fi

# Hardware-accelerated rendering when a GPU is available (falls back to software)
if [[ -d /dev/dri ]]; then
  args+=(--device /dev/dri)
  for g in video render; do
    gid=$(getent group "$g" | cut -d: -f3 || true)
    [[ -n "$gid" ]] && args+=(--group-add "$gid")
  done
fi

exec docker run "${args[@]}" "$IMAGE" "$@"
