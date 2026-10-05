#!/bin/sh
# Compile every <locale>.po next to this script into
# package/contents/locale/<locale>/LC_MESSAGES/plasma_applet_dev.greenpt.credits.mo
# Plasma loads translations from that exact path and file name.
# See: https://develop.kde.org/docs/plasma/widget/translations-i18n/
#
# Requires: gettext (msgfmt)

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
plasmoidName="dev.greenpt.credits"
projectName="plasma_applet_${plasmoidName}"

#---
if ! command -v msgfmt >/dev/null 2>&1; then
    echo "[build] Error: msgfmt not found. Install the gettext package."
    exit 1
fi

echo "[build] Compiling messages"
catalogs=$(find "${DIR}" -maxdepth 1 -name '*.po' | sort)
for cat in ${catalogs}; do
    catLocale=$(basename "${cat%.*}")
    installPath="${DIR}/../contents/locale/${catLocale}/LC_MESSAGES/${projectName}.mo"

    echo "[build] ${catLocale} -> ${installPath}"
    mkdir -p "$(dirname "${installPath}")"
    msgfmt -o "${installPath}" "${cat}"
done
echo "[build] Done building messages"
