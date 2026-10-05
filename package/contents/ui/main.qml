/*
 * GreenPT Credits — Plasma 6 panel widget
 *
 * Polls the GreenPT API for the remaining API credit and shows it in the
 * panel. The balance is read from the `x-credits-remaining` response
 * header. The cheapest request that returns this header is a
 * chat-completions call with a bogus model name: it fails with 400
 * "Unsupported model" and is not billed.
 */

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string cfgApiKey: Plasmoid.configuration.apiKey
    readonly property string cfgRegion: Plasmoid.configuration.region
    readonly property real cfgLowThreshold: Plasmoid.configuration.lowThreshold
    readonly property int refreshSeconds: Math.max(10, Plasmoid.configuration.refreshSeconds)

    readonly property bool missingKey: cfgApiKey.length === 0
    readonly property string baseUrl: cfgRegion === "us" ? "https://api.us.greenpt.ai"
                                                         : "https://api.greenpt.ai"
    readonly property string regionName: cfgRegion === "us" ? "US" : "EU"

    // Poll state
    property bool inFlight: false
    property int pollSeq: 0
    property var currentXhr: null
    property bool haveBalance: false
    property real balance: 0.0
    property string lastUpdateTime: ""
    property string statusMessage: ""

    readonly property string displayText: {
        if (missingKey)
            return i18n("-.--");
        if (haveBalance)
            return Number(balance).toFixed(2) + " \u20AC";
        return "\u2014";
    }

    readonly property string tooltipMain: missingKey ? i18n("-.--")
                                                    : displayText

    readonly property string tooltipSub: {
        var lines = [];
        if (statusMessage !== "")
            lines.push("GreenPT " + regionName + ": " + statusMessage);
        else if (haveBalance)
            lines.push("GreenPT " + regionName + ": " + Number(balance).toFixed(2) + " \u20AC remaining");
        else
            lines.push("GreenPT " + regionName + ": " + i18n("waiting for first update\u2026"));
        if (lastUpdateTime !== "")
            lines.push(i18n("Last update:") + " " + lastUpdateTime);
        return lines.join("\n");
    }

    preferredRepresentation: compactRepresentation

    toolTipMainText: tooltipMain
    toolTipSubText: tooltipSub

    onCfgApiKeyChanged: {
        root.haveBalance = false;
        keyDebounce.restart();
    }
    onCfgRegionChanged: {
        root.haveBalance = false;
        refresh();
    }
    onCfgLowThresholdChanged: {}  // recolors via binding
    onRefreshSecondsChanged: pollTimer.restart()

    Component.onCompleted: pollTimer.restart()

    Timer {
        id: pollTimer
        interval: root.refreshSeconds * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    // Debounces config-dialog edits: the API key field emits a change per
    // keystroke, and each one used to fire an HTTP request with a partial key.
    Timer {
        id: keyDebounce
        interval: 500
        onTriggered: root.refresh()
    }

    // The key goes verbatim into an HTTP request header, so restrict it to
    // printable ASCII: anything else could break the header line.
    function keyIsSafe(key) {
        for (var i = 0; i < key.length; i++) {
            var c = key.charCodeAt(i);
            if (c < 0x21 || c > 0x7e)
                return false;
        }
        return true;
    }

    function refresh() {
        // pollTimer.triggeredOnStart fires poll() immediately on restart.
        pollTimer.restart();
    }

    function poll() {
        if (root.inFlight) {
            // Invalidate any in-flight request: config may have changed
            // (key/region) and its response must not be applied anymore.
            root.pollSeq++;
            if (root.currentXhr)
                root.currentXhr.abort();
            root.currentXhr = null;
            root.inFlight = false;
        }
        if (root.missingKey) {
            root.haveBalance = false;
            root.statusMessage = i18n("no API key set — configure the widget");
            return;
        }
        if (!keyIsSafe(root.cfgApiKey)) {
            root.haveBalance = false;
            root.statusMessage = i18n("API key contains invalid characters — fix it in settings");
            return;
        }

        var seq = ++root.pollSeq;
        root.inFlight = true;

        var xhr = new XMLHttpRequest();
        root.currentXhr = xhr;
        xhr.open("POST", root.baseUrl + "/v1/chat/completions");
        xhr.setRequestHeader("Authorization", "Bearer " + root.cfgApiKey);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 15000;

        xhr.onreadystatechange = function() {
            if (seq !== root.pollSeq)
                return;
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.inFlight = false;

            if (xhr.status === 401 || xhr.status === 403) {
                root.statusMessage = i18n("invalid API key (HTTP %1)", xhr.status);
                return;
            }

            if (xhr.status === 0)
                return; // network-level failure, already handled by onerror/ontimeout

            var header = xhr.getResponseHeader("x-credits-remaining");
            if (header === null || header === "") {
                root.statusMessage = i18n("unexpected response (HTTP %1 without balance header)", xhr.status);
                return;
            }

            var value = Number(header);
            if (isNaN(value)) {
                root.statusMessage = i18n("unexpected response (non-numeric balance)");
                return;
            }

            root.balance = value;
            root.haveBalance = true;
            root.lastUpdateTime = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss");
            root.statusMessage = "";
        };

        xhr.onerror = function() {
            if (seq !== root.pollSeq)
                return;
            root.inFlight = false;
            root.statusMessage = i18n("network error");
        };

        xhr.ontimeout = function() {
            if (seq !== root.pollSeq)
                return;
            root.inFlight = false;
            root.statusMessage = i18n("network timeout");
        };

        xhr.send(JSON.stringify({
            "model": "__balance_poll__",
            "messages": []
        }));
    }

    Component {
        id: compactComponent

        Item {
            id: compact

            implicitWidth: label.implicitWidth
                           + Kirigami.Units.smallSpacing * 2
            implicitHeight: label.implicitHeight

            PlasmaComponents3.Label {
                id: label
                anchors.centerIn: parent
                text: root.displayText
                textFormat: Text.PlainText
                color: root.haveBalance && root.balance < root.cfgLowThreshold
                       ? Kirigami.Theme.negativeTextColor
                       : Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
            }
        }
    }

    compactRepresentation: compactComponent
    fullRepresentation: compactComponent
}
