import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_apiKey: apiKeyField.text
    property string cfg_region: "eu"
    property int cfg_refreshSeconds: 300
    property real cfg_lowThreshold: 5.0

    Kirigami.FormLayout {
        QQC2.Label {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("GreenPT")
            text: i18n("API settings")
        }

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18n("API key:")
            echoMode: TextInput.Password
            placeholderText: i18n("Paste your GreenPT API key")
            QQC2.ToolTip.text: i18n("Stored in plaintext in the Plasma configuration file")
            QQC2.ToolTip.visible: hovered
        }

        QQC2.ComboBox {
            id: regionCombo
            Kirigami.FormData.label: i18n("Region:")
            textRole: "text"
            model: [
                { text: "EU", value: "eu" },
                { text: "US", value: "us" }
            ]
            currentIndex: cfg_region === "us" ? 1 : 0
            onActivated: (index) => {
                cfg_region = model[index].value;
            }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Refresh interval (seconds):")
            from: 10
            to: 86400
            stepSize: 10
            editable: true
            value: cfg_refreshSeconds
            onValueModified: cfg_refreshSeconds = value
        }

        QQC2.SpinBox {
            id: thresholdSpin
            Kirigami.FormData.label: i18n("Low balance threshold (EUR):")
            from: 0
            to: 10000000
            decimals: 2
            stepSize: 100
            editable: true
            value: cfg_lowThreshold * 100
            onValueModified: cfg_lowThreshold = value / 100
        }
    }
}
