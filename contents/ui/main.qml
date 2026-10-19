import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    readonly property var sensors: JSON.parse(Plasmoid.configuration.sensors)
    readonly property bool horizontal: Plasmoid.formFactor !== 3 // 3 = Vertical
    // formFactor 2 = Horizontal panel, 3 = Vertical panel
    readonly property bool inPanel: Plasmoid.formFactor === 2 || Plasmoid.formFactor === 3

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: "Usage Peek"
    toolTipSubText: sensors.length ? sensors.map(s => (s.tag ? s.tag + " – " : "") + s.name).join("\n") : i18n("No sensors selected. Right-click → Configure…")

    // Panel thickness comes from the panel itself (root), never from our own content: no size loop.
    readonly property real thickness: horizontal ? root.height : root.width

    fullRepresentation: Item {
        id: full
        // Outer padding before and after the whole widget, along the panel's long axis
        readonly property real padX: (root.inPanel && !root.horizontal) ? 0 : Plasmoid.configuration.outerPadding * 2
        readonly property real padY: (root.inPanel && !root.horizontal) ? Plasmoid.configuration.outerPadding * 2 : 0
        // In a panel only the panel's long axis follows the content; the other axis is the panel's.
        // On the desktop the widget is freely resizable (graph / grid fill the whole card).
        Layout.minimumWidth:  !root.inPanel ? Kirigami.Units.gridUnit * 8 : ((root.inPanel && !root.horizontal) ? 0 : (root.sensors.length ? grid.implicitWidth + full.padX : Kirigami.Units.iconSizes.medium))
        Layout.minimumHeight: !root.inPanel ? Kirigami.Units.gridUnit * 6 : ((root.inPanel && root.horizontal)  ? 0 : (root.sensors.length ? grid.implicitHeight + full.padY : Kirigami.Units.iconSizes.medium))
        Layout.preferredWidth:  !root.inPanel ? Kirigami.Units.gridUnit * 18 : Layout.minimumWidth
        Layout.preferredHeight: !root.inPanel ? Kirigami.Units.gridUnit * 14 : Layout.minimumHeight

        GridLayout {
            id: grid
            anchors.centerIn: parent
            visible: root.inPanel && root.sensors.length > 0
            rows: root.horizontal ? 1 : -1
            columns: root.horizontal ? -1 : 1
            columnSpacing: Plasmoid.configuration.itemSpacing
            rowSpacing: Plasmoid.configuration.itemSpacing

            Repeater {
                model: root.sensors
                SensorItem {
                    required property var modelData
                    sensorId: modelData.sensorId
                    sensorName: modelData.name
                    sensorTag: modelData.tag ?? ""
                    sensorIcon: modelData.icon ?? "auto"
                    cfg: Plasmoid.configuration
                    inPanel: root.inPanel
                    panelThickness: root.thickness
                }
            }
        }

        // Empty state: just an icon in a panel (hover for the hint), text on the desktop
        Kirigami.Icon {
            anchors.centerIn: parent
            visible: root.sensors.length === 0 && root.inPanel
            source: "utilities-system-monitor"
            width: Math.min(parent.width, parent.height); height: width
        }
        DesktopView {
            anchors.fill: parent
            visible: !root.inPanel
            sensors: root.sensors
        }
    }
}
