#!/usr/bin/env bash
# Cattura lo schermo del dispositivo Android collegato e stampa il percorso
# del PNG, così Claude può aprirlo e vedere la UI reale.
#
# Uso: tool/screenshot.sh [nome]   (default: data e ora)
# Va lanciato da Git Bash: in PowerShell 5.1 il redirect `>` corrompe il PNG.
set -euo pipefail

find_adb() {
  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return
  fi
  local sdk
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "${LOCALAPPDATA:-}/Android/Sdk"; do
    if [[ -n "$sdk" && -x "$sdk/platform-tools/adb.exe" ]]; then
      echo "$sdk/platform-tools/adb.exe"
      return
    fi
    if [[ -n "$sdk" && -x "$sdk/platform-tools/adb" ]]; then
      echo "$sdk/platform-tools/adb"
      return
    fi
  done
  echo "adb non trovato: aggiungi platform-tools al PATH o imposta ANDROID_HOME" >&2
  exit 1
}

adb="$(find_adb)"

if ! "$adb" get-state >/dev/null 2>&1; then
  echo "Nessun dispositivo collegato (controlla 'adb devices')" >&2
  exit 1
fi

# A schermo spento screencap restituisce un'immagine tutta nera.
if ! "$adb" shell dumpsys power | grep -q "mWakefulness=Awake"; then
  echo "Lo schermo del telefono è spento: sbloccalo e riprova" >&2
  exit 1
fi

# Cattura solo Leviathan, mai altre app (home, notifiche, chat...).
package="com.leviathan.leviathan"
if ! "$adb" shell dumpsys window | grep "mFocusedApp=" | grep -q "$package/"; then
  echo "Leviathan non è in primo piano sul telefono: aprila e riprova" >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="$root/.screenshots"
mkdir -p "$out_dir"

name="${1:-$(date +%Y%m%d-%H%M%S)}"
out="$out_dir/$name.png"

"$adb" exec-out screencap -p >"$out"

# Un PNG valido inizia con la firma \x89PNG.
if [[ "$(head -c 4 "$out" | tail -c 3)" != "PNG" ]]; then
  echo "Screenshot non valido: $out" >&2
  exit 1
fi

echo "$out"
