# Scale to 1080p tall, width from the source aspect. `-2` (not `-1`) keeps the
# width even, which H.264 4:2:0 requires. A fixed 1920:1080 instead encodes
# every input into that exact box and leans on a non-square SAR to display it
# right — wasted bitrate, and wrong on anything that ignores SAR.
transcode-video-1080p() {
  ffmpeg -i "$1" -vf scale=-2:1080 -c:v libx264 -preset fast -crf 23 -c:a copy "${1%.*}-1080p.mp4"
}

# Re-encode to HEVC at the SOURCE resolution — this does not scale anything, so
# feed it 4K if you want 4K out. Slower preset and a real audio encode, for
# archiving rather than sharing.
transcode-video-hevc() {
  ffmpeg -i "$1" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k "${1%.*}-optimized.mp4"
}

# Transcode any image to JPG image that's great for shrinking wallpapers
img2jpg() {
  local img="$1"
  shift

  magick "$img" "$@" -quality 95 -strip "${img%.*}-converted.jpg"
}

# Transcode any image to JPG image that's great for sharing online without being too big
img2jpg-small() {
  local img="$1"
  shift

  magick "$img" "$@" -resize 1080x\> -quality 95 -strip "${img%.*}-small.jpg"
}
# Transcode any image to JPG image that's great for sharing online without being too big
img2jpg-medium() {
  local img="$1"
  shift

  magick "$img" "$@" -resize 1800x\> -quality 95 -strip "${img%.*}-medium.jpg"
}

# Transcode any image to compressed-but-lossless PNG
img2png() {
  local img="$1"
  shift

  magick "$img" "$@" -strip -define png:compression-filter=5 \
    -define png:compression-level=9 \
    -define png:compression-strategy=1 \
    -define png:exclude-chunk=all \
    "${img%.*}-optimized.png"
}

# SSH Port Forwarding Functions
fip() {
  [[ $# -lt 2 ]] && echo "Usage: fip <host> <port1> [port2] ..." && return 1
  local host="$1" port
  shift
  for port in "$@"; do
    ssh -f -N -L "$port:localhost:$port" "$host" && echo "Forwarding localhost:$port -> $host:$port"
  done
}

dip() {
  [[ $# -eq 0 ]] && echo "Usage: dip <port1> [port2] ..." && return 1
  local port
  for port in "$@"; do
    pkill -f "ssh.*-L $port:localhost:$port" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"
  done
}

lip() {
  # pgrep -a (full command line) is Linux-only — macOS pgrep silently ignores it.
  # Resolve PIDs, then ps each so both platforms show the full forward command.
  local pid found=0
  for pid in $(pgrep -f "ssh.*-L [0-9]+:localhost:[0-9]+"); do
    found=1; ps -o pid=,args= -p "$pid"
  done
  (( found )) || echo "No active forwards"
}

# AI coding tools — `cc`/`oc`/`cx` and `ai-update` — live in ~/.config/shell/ai.zsh
