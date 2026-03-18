#!/usr/bin/env bash
# =============================================================================
# rename-interfaces.sh
# Renames network interfaces based on IP-to-name mapping.
# - Bare-metal / VM: writes udev rules (persistent) + live rename
# - Docker / container: live rename only (udev not available)
# =============================================================================

set -eo pipefail

# ---------------------------------------------------------------------------
# IP → desired interface name mapping
# ---------------------------------------------------------------------------
declare -A ip2name=(
  [172.31.255.253]=eth2
  [10.0.1.2]=eth0
  [10.0.1.10]=eth1
  [10.0.1.3]=eth0
  [10.0.1.19]=eth1
  [10.0.1.11]=eth0
  [10.0.1.18]=eth1
  [172.16.123.142]=eth2
  [172.16.123.158]=eth2
  [172.31.255.252]=eth2
  [10.0.2.2]=eth0
  [10.0.2.10]=eth1
  [10.0.2.3]=eth0
  [10.0.2.19]=eth1
  [10.0.2.11]=eth0
  [10.0.2.18]=eth1
  [172.16.123.30]=eth2
  [172.16.123.14]=eth2
  [172.16.255.19]=eth3
)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
UDEV_RULES_FILE="/etc/udev/rules.d/70-persistent-net.rules"
DRY_RUN=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()   { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --dry-run   Show what would be done without making changes
  -h, --help  Show this help

Behaviour:
  In a container (Docker/LXC): performs live rename via 'ip link' only.
  On bare-metal/VM:            writes persistent udev rules AND renames live.

Examples:
  sudo $(basename "$0")
  sudo $(basename "$0") --dry-run
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage ;;
    *) error "Unknown argument: $arg" ;;
  esac
done

# ---------------------------------------------------------------------------
# Root check
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" == false && $EUID -ne 0 ]]; then
  error "This script must be run as root (use sudo), or pass --dry-run to preview."
fi

# ---------------------------------------------------------------------------
# Detect container environment
# ---------------------------------------------------------------------------
in_container() {
  [[ -f "/.dockerenv" ]] && return 0
  grep -qE '(docker|lxc|containerd|kubepods)' /proc/1/cgroup 2>/dev/null && return 0
  grep -qE '(docker|lxc|containerd|kubepods)' /proc/self/mountinfo 2>/dev/null && return 0
  return 1
}

IS_CONTAINER=false
if in_container; then
  IS_CONTAINER=true
  log "Container environment detected — skipping udev, using live rename only."
else
  log "Bare-metal/VM environment detected — will write udev rules and rename live."
fi

# ---------------------------------------------------------------------------
# Discover interfaces, IPs, and MACs
# ---------------------------------------------------------------------------
log "Scanning network interfaces..."

declare -A iface_ip=()
declare -A iface_mac=()

for iface_path in /sys/class/net/*/; do
  iface="${iface_path%/}"
  iface="${iface##*/}"

  [[ -z "$iface" ]] && continue
  [[ "$iface" =~ ^(lo|docker|veth|virbr|tun|tap|br-) ]] && continue

  mac=""
  mac=$(cat "/sys/class/net/${iface}/address" 2>/dev/null) || true
  [[ -z "$mac" || "$mac" == "00:00:00:00:00:00" ]] && continue

  ip_addr=""
  ip_addr=$(ip -4 addr show dev "$iface" 2>/dev/null \
    | awk '/inet / {split($2,a,"/"); print a[1]; exit}') || true

  iface_mac[$iface]="$mac"
  if [[ -n "$ip_addr" ]]; then
    iface_ip[$iface]="$ip_addr"
  fi
done

# ---------------------------------------------------------------------------
# Build rename plan
# ---------------------------------------------------------------------------
log "Matching interfaces to desired names..."

declare -A rename_plan=()
declare -A rename_mac=()

for iface in "${!iface_ip[@]}"; do
  ip_addr="${iface_ip[$iface]}"
  desired="${ip2name[$ip_addr]:-}"

  if [[ -z "$desired" ]]; then
    warn "  $iface ($ip_addr) — no mapping found, skipping."
    continue
  fi

  mac="${iface_mac[$iface]:-}"

  if [[ "$iface" == "$desired" ]]; then
    log "  $iface ($ip_addr) — already correct, skipping."
  else
    log "  $iface ($ip_addr, MAC $mac) → rename to '$desired'"
    rename_plan[$iface]="$desired"
    rename_mac[$iface]="$mac"
  fi
done

if [[ ${#rename_plan[@]} -eq 0 ]]; then
  log "Nothing to rename. Exiting."
  exit 0
fi

# ---------------------------------------------------------------------------
# Write udev rules (bare-metal/VM only)
# ---------------------------------------------------------------------------
write_udev_rules() {
  local content=""
  content+="# Auto-generated by rename-interfaces.sh on $(date)\n"
  content+="# Persistent network interface name assignments\n\n"

  for iface in "${!rename_mac[@]}"; do
    content+="SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"${rename_mac[$iface]}\", NAME=\"${rename_plan[$iface]}\"\n"
  done

  if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would write ${UDEV_RULES_FILE}:"
    echo "---"
    printf "%b" "$content"
    echo "---"
    return
  fi

  mkdir -p "$(dirname "$UDEV_RULES_FILE")"

  if [[ -f "$UDEV_RULES_FILE" ]]; then
    cp "$UDEV_RULES_FILE" "${UDEV_RULES_FILE}.bak.$(date +%s)"
    log "Backed up existing rules."
  fi

  printf "%b" "$content" > "$UDEV_RULES_FILE"
  log "Wrote udev rules to ${UDEV_RULES_FILE}"

  if command -v udevadm &>/dev/null; then
    udevadm control --reload-rules
    log "Reloaded udev rules."
  else
    warn "udevadm not found — rules written but will apply on next boot only."
  fi
}

# ---------------------------------------------------------------------------
# Live rename via ip link
# ---------------------------------------------------------------------------
live_rename() {
  log "Performing live interface renames..."
  for iface in "${!rename_plan[@]}"; do
    desired="${rename_plan[$iface]}"
    if [[ "$DRY_RUN" == true ]]; then
      log "  [DRY-RUN] ip link set '$iface' down; ip link set '$iface' name '$desired'; ip link set '$desired' up"
    else
      log "  $iface → $desired"
      ip link set "$iface" down
      ip link set "$iface" name "$desired"
      ip link set "$desired" up
      log "  $desired is up."
    fi
  done
}

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
if [[ "$IS_CONTAINER" == false ]]; then
  write_udev_rules
fi

live_rename

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
log "===== Summary ====="
for iface in "${!rename_plan[@]}"; do
  echo "  ${iface}  →  ${rename_plan[$iface]}  (MAC: ${rename_mac[$iface]:-})"
done