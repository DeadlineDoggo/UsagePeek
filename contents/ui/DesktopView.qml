import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Desktop representation: resizable card with either a history graph or a zoomed gauge grid
Item {
    id: dv

    required property var sensors
    readonly property var cfg: Plasmoid.configuration
    readonly property color fg: cfg.useCustomTextColor ? cfg.textColor : Kirigami.Theme.textColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: dv.cfg.showTitle
            text: i18n("Usage Peek")
            horizontalAlignment: Text.AlignHCenter
            color: dv.fg
            font.pixelSize: Math.round((dv.cfg.fontSize > 0 ? dv.cfg.fontSize : Kirigami.Theme.defaultFont.pixelSize) * 1.3)
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: dv.sensors.length === 0
            text: i18n("No sensors. Right-click → Configure…")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Loader {
            Layout.fillWidth: true; Layout.fillHeight: true
            active: dv.sensors.length > 0
            sourceComponent: dv.cfg.desktopMode === "grid" ? gridC : graphC
        }
    }

    Component { id: graphC
        UsageChart { sensors: dv.sensors }
    }

    Component { id: gridC
        Item {
            id: area
            readonly property int n: dv.sensors.length
            readonly property int cols: dv.cfg.gridColumns > 0
                ? Math.min(dv.cfg.gridColumns, Math.max(1, n))
                : Math.max(1, Math.min(n, Math.floor(width / (dv.cfg.gaugeSize * 1.5))))
            readonly property int rowCount: Math.max(1, Math.ceil(n / cols))
            readonly property real cellW: width / cols
            readonly property real cellH: height / rowCount

            GridLayout {
                anchors.fill: parent
                columns: area.cols
                columnSpacing: 0
                rowSpacing: 0
                Repeater {
                    model: dv.sensors
                    Item {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: area.cellW
                        Layout.preferredHeight: area.cellH
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: Kirigami.Units.cornerRadius
                            color: Qt.rgba(dv.fg.r, dv.fg.g, dv.fg.b, 0.05)
                            border.width: 1
                            border.color: Qt.rgba(dv.fg.r, dv.fg.g, dv.fg.b, 0.10)
                        }
                        SensorItem {
                            anchors.centerIn: parent
                            labelMaxWidth: Math.max(40, area.cellW - 16)
                            sensorId: modelData.sensorId
                            sensorName: modelData.name
                            sensorTag: modelData.tag ?? ""
                            sensorIcon: modelData.icon ?? "auto"
                            cfg: dv.cfg
                            inPanel: false
                            sizeOverride: dv.cfg.scaleGauges
                                ? Math.max(16, Math.min(area.cellW * 0.75, area.cellH * (dv.cfg.showName ? 0.5 : 0.6))) : 0
                        }
                    }
                }
            }
        }
    }
}
