#!/usr/bin/env bash
# ==============================================================================
# lenovo-tab-debloat — ADB Debloater for Lenovo Idea Tab / Tab Plus / ZUI Tablets
#Tested on: Lenovo Idea Tab 11 (TB336FU / sycamore_row_wifi, Android 16 / ZUI)
# ==============================================================================

set -euo pipefail

# Core silent app installers, adware daemons, telemetry, carrier/demo stubs
CORE_BLOAT_PACKAGES=(
  # 1. Silent App & Game Pushers (IronSource Aura, Lenovo Discovery, Opera)
  "com.aura.oobe.lenovo"              # IronSource Aura / AppCloud silent game/app installer
  "com.discovery.oobe"                # Lenovo Discovery OOBE app pusher
  "com.lenovo.dsa"                    # OCZ_DeployServiceApp (silent background app deployment)
  "com.lenovo.ocpl"                   # OCZ_ClientDownloader (silent background APK downloader)
  "com.opera.preinstall"              # Opera preinstall partner stub

  # 2. Lenovo Vantage, Ad Portals & Promotional Push Daemons
  "com.tblenovo.center"               # TabletVantage (Lenovo Vantage promotional portal)
  "com.tblenovo.lenovowhatsnew"       # LenovoWhatsNew promotional popups
  "com.tblenovo.tabpushout"           # TabletPushOut notification ad service

  # 3. Lenovo Telemetry, Analytics & Cloud Nagging
  "com.lenovo.ue.device"              # TabletUE (User Experience telemetry daemon)
  "com.tblenovo.ue.config"            # VantageResources telemetry config
  "com.lenovo.tbengine"               # UDSEngine background analytics service
  "com.lenovo.lenovoprivacy"          # ZuiLenovoPrivacy telemetry consent daemon
  "com.lenovo.lsf"                    # LenovoID account service
  "com.lenovo.lsf.device"             # LSF-Device-Phone push/account daemon
  "com.lmsa.app.lmsapad"              # LTHD (Lenovo Rescue & Smart Assistant PC daemon)

  # 4. Retail Store Demo & Carrier Provisioning Stubs
  "com.lenovo.tab_extreme"            # ZUIEpos retail store demo loop
  "com.motorola.demo"                 # ZUIDemoMode retail demo mode
  "com.motorola.omadm.vzw"            # VzwDM (Verizon OMA-DM provisioning on Wi-Fi tablets)
  "com.motorola.omadm.service"        # DMService carrier provisioning

  # 5. Hidden Facebook System Updaters & Google Kids Space Launcher
  "com.facebook.appmanager"           # Background Facebook App Manager
  "com.facebook.services"             # Background Facebook Services
  "com.facebook.system"               # facebook_installer (privileged silent APK installer)
  "com.google.android.apps.kids.home" # Google Kids Space launcher bloat (does NOT affect Family Link)
)

# Optional Lenovo / ZUI preloaded apps & background services
OPTIONAL_ZUI_PACKAGES=(
  "com.zui.weather"                   # Lenovo / ZUI Weather app
  "com.lenovo.weathercenter"          # Background weather provider daemon
  "com.zui.notes"                     # Preinstalled ZUI Notes app
  "com.zui.recorder"                  # Preinstalled XuiRecorder voice recorder
  "com.hf.app.wallpaper"              # ZuiHFWallpaper store/service
  "com.motorola.mobiledesktop"        # Moto Ready For / Smart Connect app
  "com.motorola.mobiledesktop.core"   # Ready For Core background service
  "com.zui.udevice"                   # ZuiUDevice cross-device interconnection daemon
  "com.zui.ai.aiservice"              # ZuiAIService background daemon
  "com.zui.ai.lens"                   # ZuiAILens service
  "com.zui.pp"                        # ZuiPP privacy portal stub
)

ADB_BIN="${ADB_BIN:-adb}"
SERIAL=""
PAIR_TARGET=""
PAIR_CODE=""
USER_ID="0"
MODE="remove"       # remove | restore | audit
INCLUDE_OPTIONAL=1  # 1 = remove both core + optional ZUI packages; 0 = core only
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  ./debloat.sh [options]

Options:
  -s, --serial <ip:port|serial>   Target ADB device (or connect to <ip:port> over Wi-Fi)
  -p, --pair <ip:port> <code>     Pair over Android 11+ Wireless Debugging first, then auto-discover connect port
  -u, --user <id>                 Android user ID (default: 0)
  --core-only                     Only remove core adware/installers/telemetry (keep ZUI Notes/Weather/Smart Connect)
  --audit                         List which bloatware packages are currently installed without modifying anything
  --restore                       Re-enable / restore previously removed packages (`cmd package install-existing`)
  --dry-run                       Print ADB commands without executing them
  -h, --help                      Show this help message

Examples:
  # Pair via Android Wireless Debugging, auto-discover the connect port, and debloat everything:
  ./debloat.sh --pair 192.168.1.222:38167 381571

  # Connect to an already-paired tablet over Wi-Fi and remove all bloatware:
  ./debloat.sh -s 192.168.1.222:39921

  # Audit what bloatware is currently active on a USB-connected tablet:
  ./debloat.sh --audit

  # Restore all packages if needed:
  ./debloat.sh -s 192.168.1.222:39921 --restore
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial)
      SERIAL="$2"
      shift 2
      ;;
    -p|--pair)
      PAIR_TARGET="$2"
      PAIR_CODE="$3"
      shift 3
      ;;
    -u|--user)
      USER_ID="$2"
      shift 2
      ;;
    --core-only)
      INCLUDE_OPTIONAL=0
      shift
      ;;
    --audit)
      MODE="audit"
      shift
      ;;
    --restore)
      MODE="restore"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
  echo "Error: '$ADB_BIN' not found in PATH. Install Android platform-tools or set ADB_BIN=/path/to/adb." >&2
  exit 1
fi

discover_connect_port() {
  local host="$1"
  local exclude_port="${2:-0}"
  python3 - "$host" "$exclude_port" <<'PYEOF'
import socket, sys
from concurrent.futures import ThreadPoolExecutor

host = sys.argv[1]
exclude = int(sys.argv[2])

def probe(port):
    if port == exclude:
        return None
    s = socket.socket()
    s.settimeout(0.1)
    try:
        s.connect((host, port))
        s.close()
        return port
    except Exception:
        s.close()
        return None

with ThreadPoolExecutor(max_workers=250) as ex:
    open_ports = [p for p in ex.map(probe, range(30000, 46000)) if p]

print(open_ports[0] if open_ports else "")
PYEOF
}

if [[ -n "$PAIR_TARGET" ]]; then
  echo "==> Pairing with $PAIR_TARGET ..."
  "$ADB_BIN" pair "$PAIR_TARGET" "$PAIR_CODE"
  HOST="${PAIR_TARGET%%:*}"
  PAIR_PORT="${PAIR_TARGET##*:}"
  if [[ -z "$SERIAL" ]]; then
    echo "==> Scanning $HOST for active Wireless Debugging connect port..."
    DISCOVERED_PORT="$(discover_connect_port "$HOST" "$PAIR_PORT")"
    if [[ -z "$DISCOVERED_PORT" ]]; then
      echo "Error: Paired successfully, but could not auto-discover the Wireless Debugging connect port on $HOST." >&2
      echo "Pass -s <ip:port> using the IP & Port shown on the main Wireless Debugging screen." >&2
      exit 1
    fi
    SERIAL="${HOST}:${DISCOVERED_PORT}"
    echo "==> Discovered connect endpoint: $SERIAL"
  fi
fi

ADB_ARGS=()
if [[ -n "$SERIAL" ]]; then
  if [[ "$SERIAL" == *:* ]]; then
    "$ADB_BIN" connect "$SERIAL" >/dev/null
  fi
  ADB_ARGS=(-s "$SERIAL")
fi

MODEL="$("$ADB_BIN" "${ADB_ARGS[@]}" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
ANDROID_VER="$("$ADB_BIN" "${ADB_ARGS[@]}" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
echo "==> Connected to device: ${MODEL:-Unknown} (Android ${ANDROID_VER:-Unknown}, user $USER_ID)"

PACKAGES=("${CORE_BLOAT_PACKAGES[@]}")
if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
  PACKAGES+=("${OPTIONAL_ZUI_PACKAGES[@]}")
fi

INSTALLED_LIST="$("$ADB_BIN" "${ADB_ARGS[@]}" shell pm list packages --user "$USER_ID" | tr -d '\r')"

if [[ "$MODE" == "audit" ]]; then
  echo "==> Auditing ${#PACKAGES[@]} known bloatware packages for user $USER_ID:"
  ACTIVE_COUNT=0
  for pkg in "${PACKAGES[@]}"; do
    if grep -qx "package:${pkg}" <<<"$INSTALLED_LIST"; then
      printf "  [INSTALLED] %s\n" "$pkg"
      ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
    else
      printf "  [CLEAN]     %s\n" "$pkg"
    fi
  done
  echo "==> Audit complete: $ACTIVE_COUNT / ${#PACKAGES[@]} bloatware packages currently active."
  exit 0
fi

if [[ "$MODE" == "restore" ]]; then
  echo "==> Restoring ${#PACKAGES[@]} packages for user $USER_ID..."
  for pkg in "${PACKAGES[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] $ADB_BIN ${ADB_ARGS[*]} shell cmd package install-existing --user $USER_ID $pkg"
    else
      OUT="$("$ADB_BIN" "${ADB_ARGS[@]}" shell cmd package install-existing --user "$USER_ID" "$pkg" 2>&1 | tr -d '\r')"
      printf "  %-38s %s\n" "$pkg" "$OUT"
    fi
  done
  exit 0
fi

echo "==> Removing ${#PACKAGES[@]} bloatware packages for user $USER_ID..."
REMOVED=0
SKIPPED=0
for pkg in "${PACKAGES[@]}"; do
  if ! grep -qx "package:${pkg}" <<<"$INSTALLED_LIST"; then
    printf "  %-38s [already removed]\n" "$pkg"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] $ADB_BIN ${ADB_ARGS[*]} shell pm uninstall -k --user $USER_ID $pkg"
    REMOVED=$((REMOVED + 1))
  else
    OUT="$("$ADB_BIN" "${ADB_ARGS[@]}" shell pm uninstall -k --user "$USER_ID" "$pkg" 2>&1 | tr -d '\r')"
    printf "  %-38s %s\n" "$pkg" "$OUT"
    if [[ "$OUT" == *"Success"* ]]; then
      REMOVED=$((REMOVED + 1))
    fi
  fi
done

echo "==> Done! Removed: $REMOVED | Already clean: $SKIPPED | Total checked: ${#PACKAGES[@]}"
