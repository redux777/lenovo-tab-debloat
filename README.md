# lenovo-tab-debloat

A lightweight, dependency-free ADB debloat script for **Lenovo Idea Tab 11 (`TB336FU`)** and other **Lenovo ZUI / Android 14–16 tablets**.

Lenovo tablets ship with several background app-deployment daemons (**IronSource Aura**, **Lenovo Discovery**, **`OCZ_DeployServiceApp`**, **`OCZ_ClientDownloader`**, and **Facebook `facebook_installer`**) that silently download and install sponsored puzzle games and promotional apps in the background, alongside Lenovo Vantage popups, telemetry uploaders, retail store demo loops, and Verizon OMA-DM carrier services.

`debloat.sh` removes all **34** of these packages for the active Android user (`pm uninstall -k --user 0`) **without requiring root or unlocking the bootloader**, while preserving OTA system updates, stylus/pen support, split-screen, Dolby Atmos audio, Google Play Services, and Google Family Link parental controls.

---

## Features

- **One-Command Wireless Debugging Pairing + Auto-Discovery**: Pass `--pair <ip:port> <code>` straight from the tablet's *Pair with pairing code* popup—the script pairs, automatically scans and discovers the tablet's randomized Wireless Debugging connect port (`30000–46000`), connects, and debloats in one step.
- **Two-Tier Package List**:
  - **Core Bloatware (23 packages)**: Silent app/game installers, ad pushers, Lenovo telemetry, retail demo mode, carrier provisioning, and Facebook system installer stubs.
  - **Optional Lenovo/ZUI Preloads (11 packages)**: Lenovo Weather, ZUI Notes, ZUI Voice Recorder, ZUI Wallpaper Store, Smart Connect / Ready For PC daemons, and ZUI AI background services (can be kept by passing `--core-only`).
- **Audit & Restore Modes**:
  - `--audit`: Check which bloatware packages are currently active (useful after a major OS update).
  - `--restore`: Re-enable any removed system package instantly via `cmd package install-existing`.

---

## Quick Start

### 1. Enable Wireless Debugging on the Tablet
1. Open **Settings → About tablet → Software information** (or **Version**) and tap **Build number** 7 times until *You are now a developer!* appears.
2. Open **Settings → System → Developer options → Wireless debugging** and toggle it **On** (check *Always allow on this network*).
3. Tap the word **"Wireless debugging"** to enter its submenu, then tap **"Pair device with pairing code"**.

### 2. Run `debloat.sh`

```bash
git clone https://github.com/redux777/lenovo-tab-debloat.git
cd lenovo-tab-debloat
chmod +x debloat.sh

# Pair, auto-discover the connect port, and remove all 34 bloatware packages:
./debloat.sh --pair 192.168.1.222:38167 381571
```

#### Other Usage Modes

```bash
# Connect to an already-paired tablet over Wi-Fi:
./debloat.sh -s 192.168.1.222:39921

# Run over a USB cable (when a single device is attached):
./debloat.sh

# Only remove silent installers, adware, and telemetry (keep ZUI Notes, Weather, Smart Connect):
./debloat.sh -s 192.168.1.222:39921 --core-only

# Check if an OTA update re-enabled any bloatware without making changes:
./debloat.sh -s 192.168.1.222:39921 --audit

# Restore all packages back to stock:
./debloat.sh -s 192.168.1.222:39921 --restore
```

---

## Package Reference

### Tier 1: Core Bloatware, Silent Installers & Telemetry (`23` Packages)

| Package Name | APK Path | Description |
| :--- | :--- | :--- |
| `com.aura.oobe.lenovo` | `/data/app/.../com.aura.oobe.lenovo` | **IronSource Aura / AppCloud**: Primary culprit that silently downloads and installs third-party casual games in the background. |
| `com.discovery.oobe` | `/system/priv-app/DiscoveryApps` | **Lenovo Discovery OOBE**: Background app recommendation & silent installer service. |
| `com.lenovo.dsa` | `/system/priv-app/OCZ_DeployServiceApp` | **Deploy Service App**: Privileged Lenovo background silent APK deployment daemon. |
| `com.lenovo.ocpl` | `/system/priv-app/OCZ_ClientDownloader` | **OCZ Client Downloader**: Partner daemon to `com.lenovo.dsa` that fetches promoted APKs. |
| `com.opera.preinstall` | `/system/app/OperaProvider` | **Opera Preinstall Stub**: Partner attribution/preinstall provider for Opera browser. |
| `com.tblenovo.center` | `/system/priv-app/TabletVantage` | **Lenovo Vantage**: Promotional portal, warranty upsells, and ad banners. |
| `com.tblenovo.lenovowhatsnew` | `/system/priv-app/LenovoWhatsNew` | **Lenovo What's New**: Promotional popups and feature nagging. |
| `com.tblenovo.tabpushout` | `/system/priv-app/TabletPushOut` | **Tablet PushOut**: Background promotional push notification service. |
| `com.lenovo.ue.device` | `/system/priv-app/TabletUE` | **Lenovo User Experience (UE)**: Background usage tracking and telemetry uploader. |
| `com.tblenovo.ue.config` | `/system/app/VantateResources` | **Vantage Telemetry Config**: Configuration provider for Lenovo UE analytics. |
| `com.lenovo.tbengine` | `/system/priv-app/UDSEngine` | **UDS Engine**: Lenovo background device analytics & data collection daemon. |
| `com.lenovo.lenovoprivacy` | `/system/priv-app/ZuiLenovoPrivacy` | **ZUI Privacy Daemon**: Telemetry/privacy prompt handler. |
| `com.lenovo.lsf` | `/system/priv-app/LenovoID` | **Lenovo ID**: Lenovo cloud account sign-in service & account prompts. |
| `com.lenovo.lsf.device` | `/system/priv-app/LSF-Device-Phone` | **Lenovo Services Framework**: Background push/cloud account daemon. |
| `com.lmsa.app.lmsapad` | `/product/app/LTHD` | **Lenovo Smart Assistant**: Background helper for Lenovo's Windows PC rescue tool. |
| `com.lenovo.tab_extreme` | `/system/priv-app/ZUIEpos` | **ZUI EPOS**: Electronic Point-of-Sale retail store demo loop. |
| `com.motorola.demo` | `/system/priv-app/ZUIDemoMode` | **ZUI Demo Mode**: Retail store display mode service. |
| `com.motorola.omadm.vzw` | `/system/priv-app/VzwDM` | **Verizon OMA-DM**: Cellular carrier device management on Wi-Fi-only tablets. |
| `com.motorola.omadm.service` | `/system/priv-app/DMService` | **Carrier DM Service**: Cellular OMA-DM provisioning service. |
| `com.facebook.appmanager` | `/system/app/facebook_appmanager` | **Facebook App Manager**: Background Facebook APK updater stub. |
| `com.facebook.services` | `/system/priv-app/facebook_services` | **Facebook Services**: Privileged background Facebook daemon. |
| `com.facebook.system` | `/system/priv-app/facebook_installer` | **Facebook System Installer**: Privileged silent APK installer for Meta apps. |
| `com.google.android.apps.kids.home` | `/product/priv-app/KidsHome` | **Google Kids Space**: Heavy kids-mode custom launcher bloat *(safe to remove; does **not** affect Google Family Link `com.google.android.apps.kids.familylinkhelper` or YouTube Kids)*. |

---

### Tier 2: Optional Lenovo / ZUI Preloads (`11` Packages)
*(Removed by default; kept if you pass `--core-only`)*

| Package Name | APK Path | Description |
| :--- | :--- | :--- |
| `com.zui.weather` | `/data/app/.../com.zui.weather` | Lenovo / ZUI Weather app & widget. |
| `com.lenovo.weathercenter` | `/system/priv-app/WeatherCenter` | Background weather data service. |
| `com.zui.notes` | `/system/preinstall/ZuiNotes` | Preinstalled ZUI Notes app. |
| `com.zui.recorder` | `/system/preinstall/XuiRecorder` | Preinstalled ZUI Voice Recorder app. |
| `com.hf.app.wallpaper` | `/system/preinstall/ZuiHFWallpaper` | ZUI online wallpaper store service. |
| `com.motorola.mobiledesktop` | `/product/priv-app/MotoReadyFor` | Lenovo Smart Connect / Moto Ready For cross-device app. |
| `com.motorola.mobiledesktop.core` | `/system_ext/priv-app/ReadyForCore` | Always-running background service for Smart Connect / Ready For. |
| `com.zui.udevice` | `/system/priv-app/ZuiUDevice` | ZUI cross-device discovery/continuity service. |
| `com.zui.ai.aiservice` | `/system/priv-app/ZuiAIService` | ZUI background AI service. |
| `com.zui.ai.lens` | `/system/priv-app/ZuiAILens` | ZUI AI Lens scanner service. |
| `com.zui.pp` | `/system/app/ZuiPP` | ZUI privacy portal stub. |

---

### System Packages Intentionally Preserved (Do Not Remove)

The following ZUI / Lenovo packages are required for normal tablet operation and are **never** touched by `debloat.sh`:
- `com.zui.launcher`, `com.zui.desktoplauncher`, `com.zui.homesettings` *(Default home screen, taskbar, and recents provider)*
- `com.lenovo.ota` *(System OS & security updates)*
- `com.lenovo.penservice`, `com.zui.pengen` *(Lenovo Tab Pen / active stylus support)*
- `com.lenovo.screensplit`, `com.zui.freeform.sidebar` *(Split-screen & floating window multitasking)*
- `com.dolby.daxservice` *(Dolby Atmos quad-speaker tuning)*
- `com.zui.camera`, `com.zui.camera.assistant`, `com.zui.camera.qr` *(Built-in Camera app)*
- `com.google.android.apps.kids.familylinkhelper` *(Google Family Link parental controls)*

---

## Do Removed Packages Return After OTA Updates?

- **Monthly Security / Incremental OTAs**: **No.** `pm uninstall -k --user 0` records `installed="false"` inside `/data/system/users/0/package-restrictions.xml` on the `/data` partition, which persists across standard `/system` OTA updates.
- **Major Android Version Upgrades (e.g., Android 16 → 17)**: Occasionally a major OS upgrade may introduce new package names or reset specific `/system/priv-app` states. Run `./debloat.sh --audit` after a major OS upgrade to verify or clean up any newly added packages.
