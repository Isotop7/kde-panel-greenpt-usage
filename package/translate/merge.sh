#!/bin/sh
# Extract translatable messages from the QML/JS sources into template.pot
# and merge the updated template into every <locale>.po file next to it.
# See: https://develop.kde.org/docs/plasma/widget/translations-i18n/
#
# Requires: gettext (xgettext, msgmerge)

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
plasmoidName="dev.greenpt.credits"
widgetName="${plasmoidName##*.}" # Strip namespace

#---
if ! command -v xgettext >/dev/null 2>&1 || ! command -v msgmerge >/dev/null 2>&1; then
    echo "[merge] Error: xgettext/msgmerge not found. Install the gettext package."
    exit 1
fi

echo "[merge] Extracting messages"
cd "${DIR}" || exit 1
find .. \( -name '*.qml' -o -name '*.js' \) -not -path '*/locale/*' | sort > infiles.list

xgettext \
    --files-from=infiles.list \
    --from-code=UTF-8 \
    --width=400 \
    --add-location=file \
    -C -kde -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    --package-name="${widgetName}" \
    -D . \
    -o template.pot.new \
    || { echo "[merge] error while calling xgettext. aborting."; exit 1; }

sed -i 's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' template.pot.new
sed -i 's/# SOME DESCRIPTIVE TITLE./'"# Translation of ${widgetName} in LANGUAGE"'/' template.pot.new
sed -i 's/# Copyright (C) YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/'"# Copyright (C) $(date +%Y)"'/' template.pot.new
mv template.pot.new template.pot

#---
echo "[merge] Merging messages"
catalogs=$(find . -maxdepth 1 -name '*.po' | sort)
for cat in ${catalogs}; do
    echo "[merge] ${cat}"
    catLocale=$(basename "${cat%.*}")
    msgmerge \
        --width=400 \
        --add-location=file \
        --no-fuzzy-matching \
        -o "${cat}.new" \
        "${cat}" template.pot
    sed -i 's/# Translation of '"${widgetName}"' in LANGUAGE/'"# Translation of ${widgetName} in ${catLocale}"'/' "${cat}.new"
    mv "${cat}.new" "${cat}"
done

rm -f infiles.list
echo "[merge] Done extracting messages"
