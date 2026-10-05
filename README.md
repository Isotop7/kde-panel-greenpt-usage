# GreenPT Credits — Plasma 6 panel widget

Plasma 6 plasmoid showing the remaining GreenPT API credit in the panel, read from the `x-credits-remaining` response header.

**Free polling:** chat-completions request with bogus model `__balance_poll__` → `400 Unsupported model`, unbilled, balance header still present.

## Install (user-local, no root)

    make install

Installs the plasmoid package to `~/.local/share/plasma/plasmoids/dev.greenpt.credits/`.

Reload the panel so the new widget is picked up:

    systemctl --user restart plasma-plasmashell.service

## Use

1. Panel → Edit Mode → Add Widgets → **"GreenPT Credits"**
2. Right-click item → Configure: API key (account.greenpt.ai), region (EU/US), refresh interval seconds (default 300, min 10), low-balance threshold (default 5.00).

No key → widget shows **"-.--"**. Config changes apply live.

Label: balance, 2 decimals, `€` suffix; red below threshold. Tooltip: region, value, time of last successful update; errors explain what failed (invalid key, network timeout, …) while keeping the last value on screen.

## Notes

- The API key is stored as **plain text** in the Plasma configuration file, like any plasmoid config. Anyone with read access to your home directory can read it.
- Reinstall/reload after changes: `make install && systemctl --user restart plasma-plasmashell.service`.
- Test without touching the real panel: `plasmoidviewer -a package/` (requires `plasma-sdk`).
- Uninstall: `make uninstall`, then remove the panel item.

## Config file

`~/.config/plasma-org.kde.plasma.desktop-appletsrc`, keys under the widget's `[General]` group: `apiKey`, `region` (`eu`|`us`), `refreshSeconds`, `lowThreshold`.

## Translations

UI strings use `i18n()`. To make them translatable, `make install` compiles every `package/translate/<locale>.po` into `contents/locale/<locale>/LC_MESSAGES/plasma_applet_dev.greenpt.credits.mo` (requires `gettext`). Workflow per the [KDE i18n docs](https://develop.kde.org/docs/plasma/widget/translations-i18n/):

    # after changing translatable strings:
    sh package/translate/merge.sh     # updates template.pot + merges into *.po
    # create/translate a <locale>.po copy of template.pot, then:
    make install

## Development

Pure QML/JS — no C++ backend, no cmake. Polling via QML `XMLHttpRequest`; on the expected 400 reply the request still completes and `getResponseHeader("x-credits-remaining")` is readable.

Package layout:

    package/
      metadata.json                  # KPackageStructure Plasma/Applet
      translate/                     # i18n: template.pot, *.po, merge.sh/build.sh
      contents/
        config/main.xml              # KConfig XT: apiKey, region, refreshSeconds, lowThreshold
        config/config.qml            # config dialog page registry
        ui/main.qml                  # PlasmoidItem: label + tooltip + poll timer + XHR logic
        ui/config/ConfigGeneral.qml  # config dialog page
        images/greenpt.svg
