import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// Settings for the desktop (non-panel) view
KCM.SimpleKCM {
    id: page
    property string cfg_desktopMode
    property bool   cfg_showTitle
    property int    cfg_graphMinutes
    property bool   cfg_graphFill
    property int    cfg_gridColumns
    property bool   cfg_scaleGauges

    Kirigami.FormLayout {
        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            visible: true
            text: i18n("These settings apply when the widget sits on the desktop. In a panel it always shows the compact gauges. On the desktop you can resize the widget freely.")
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Desktop view:")
            textRole: "text"; valueRole: "value"
            model: [
                { text: i18n("Usage graph"), value: "graph" },
                { text: i18n("Gauge grid (zoomed in)"), value: "grid" }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_desktopMode))
            onActivated: page.cfg_desktopMode = currentValue
        }
        QQC2.CheckBox { text: i18n("Show title"); checked: page.cfg_showTitle; onToggled: page.cfg_showTitle = checked }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Graph") }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("History (minutes):"); from: 1; to: 120; value: page.cfg_graphMinutes
                       enabled: page.cfg_desktopMode === "graph"; onValueModified: page.cfg_graphMinutes = value }
        QQC2.CheckBox { text: i18n("Fill area under the lines"); checked: page.cfg_graphFill
                        enabled: page.cfg_desktopMode === "graph"; onToggled: page.cfg_graphFill = checked }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Gauge grid") }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Columns (0 = automatic):"); from: 0; to: 12; value: page.cfg_gridColumns
                       enabled: page.cfg_desktopMode === "grid"; onValueModified: page.cfg_gridColumns = value }
        QQC2.CheckBox { text: i18n("Scale gauges to the widget size"); checked: page.cfg_scaleGauges
                        enabled: page.cfg_desktopMode === "grid"; onToggled: page.cfg_scaleGauges = checked }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            text: i18n("Without scaling, gauges use the size from Appearance. The gauge style, tags and spacing also come from Appearance.")
        }
    }
}
