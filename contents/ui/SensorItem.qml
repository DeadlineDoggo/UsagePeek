import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "gauges"
import "Tags.js" as Tags

GridLayout {
    id: si

    required property string sensorId
    required property string sensorName
    property string sensorTag: ""
    property string sensorIcon: "auto"
    property bool inPanel: false
    property real panelThickness: 0

    required property var cfg
    // Sensor missing (e.g. dGPU powered off): hide it completely; it stays saved in the config
    visible: valid
    readonly property bool isBytes: Tags.isBytes(sensorId)
    readonly property real value: sensor.value === undefined || isNaN(Number(sensor.value)) ? NaN : Number(sensor.value)
    readonly property real totalValue: totalSensor.value === undefined || isNaN(Number(totalSensor.value)) ? NaN : Number(totalSensor.value)
    readonly property bool valid: !isNaN(value)

    readonly property var thresholds: cfg.thresholds.split(",").map(Number)
    readonly property var levelColors: cfg.levelColors.split(",")
    // 1..5 : one level for each threshold passed
    readonly property int level: {
        if (!valid) return 1;
        let l = 1;
        for (const t of thresholds) if (percent >= t) l++;
        return Math.min(5, l);
    }
    readonly property color levelColor: levelColors[level - 1] ?? "red"
    // Percent sensors give 0..100 directly; byte sensors are divided by the matching "total" sensor
    readonly property real percent: !valid ? 0 : isBytes ? (totalValue > 0 ? value / totalValue * 100 : 0) : value
    readonly property real fraction: Math.max(0, Math.min(1, percent / 100))
    readonly property color fg: cfg.useCustomTextColor ? cfg.textColor : Kirigami.Theme.textColor
    // In a panel the gauge scales to the panel thickness; otherwise use the configured size
    readonly property string effectiveTag: sensorTag.length > 0 ? sensorTag : Tags.autoTag(sensorId, sensorName)
    readonly property string tagPos: cfg.tagPosition || "top"
    readonly property bool vertTag: tagPos === "top" || tagPos === "bottom"
    readonly property bool tagShown: cfg.showTag && effectiveTag.length > 0
    // In a panel, leave room for the tag label above the gauge
    readonly property real labelH: (cfg.fontSize > 0 ? cfg.fontSize : Kirigami.Theme.defaultFont.pixelSize) * 1.3
    readonly property int px: {
        if (!(inPanel && panelThickness > 0)) return Math.round(cfg.gaugeSize);
        if (cfg.displayMode === "icon") {
            // use all the room the panel leaves after the value text and a stacked tag
            const used = (cfg.showValue ? labelH + cfg.tagSpacing : 0) + (tagShown && vertTag ? labelH * 0.7 + cfg.tagSpacing : 0);
            // the panel sets the maximum; "Gauge size" can only shrink the icon below that
            return Math.max(14, Math.min(Math.round(cfg.gaugeSize), Math.round(panelThickness - used - 6)));
        }
        return Math.max(14, Math.round(panelThickness * (cfg.displayMode === "circle" ? 0.9 : 0.55) * (tagShown && vertTag ? 0.75 : 1)));
    }
    readonly property string glyph: sensorIcon === "auto" || sensorIcon.length === 0 ? Tags.autoIcon(sensorId, sensorName) : sensorIcon
    // Glyph box: every glyph gets the same height so the row looks even; only very wide ones (NVMe) are capped
    readonly property real glyphAspect: Tags.glyphAspect[glyph] ?? 1
    readonly property real glyphW: px * Math.min(glyphAspect, 1.5)
    readonly property real glyphH: glyphW / glyphAspect
    readonly property color fillColor: cfg.fillColorMode === "custom" ? cfg.fillColor : levelColor

    readonly property string valueText: {
        if (!valid) return "–";
        return isBytes ? Tags.formatBytes(value) : Math.round(value) + "%";
    }

    // Tag placement relative to the gauge: top / bottom / left / right
    columns: vertTag ? 1 : 2
    columnSpacing: cfg.tagSpacing
    rowSpacing: cfg.tagSpacing

    // Byte sensors need their "total" to know how full the gauge is
    Sensors.Sensor {
        id: totalSensor
        sensorId: si.isBytes ? Tags.totalId(si.sensorId) : ""
        updateRateLimit: si.cfg.updateRate * 1000
    }
    Sensors.Sensor {
        id: sensor
        sensorId: si.sensorId
        updateRateLimit: si.cfg.updateRate * 1000
    }

    PlasmaComponents.Label {
        visible: si.tagShown
        Layout.row: si.tagPos === "bottom" ? 1 : 0
        Layout.column: si.tagPos === "right" ? 1 : 0
        text: si.effectiveTag
        color: si.fg
        opacity: 0.75
        font.bold: true
        font.pixelSize: Math.round(Math.max(9, (si.cfg.fontSize > 0 ? si.cfg.fontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.85))
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }

    // ---- gauge ----
    Loader {
        Layout.row: si.tagPos === "top" ? 1 : 0
        Layout.column: si.tagPos === "left" ? 1 : 0
        Layout.alignment: Qt.AlignHCenter
        sourceComponent: switch (si.cfg.displayMode) {
            case "circle": return circleC;
            case "topbar": return topbarC;
            case "line":   return lineC;
            case "icon":   return iconC;
            default:       return textC;
        }
    }

    Component { id: circleC
        Item {
            implicitWidth: si.px; implicitHeight: si.px
            CircleGauge { anchors.fill: parent; fraction: si.fraction; color: si.levelColor }
            ValueLabel { host: si; anchors.centerIn: parent; font.pixelSize: Math.round(Math.max(8, si.px * 0.28)) }
        }
    }
    Component { id: topbarC
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            BarGauge { Layout.preferredWidth: si.px * 1.6; thickness: Math.max(6, si.px * 0.18)
                       fraction: si.fraction; color: si.levelColor }
            ValueLabel { host: si;}
        }
    }
    Component { id: lineC
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            ValueLabel { host: si;}
            BarGauge { Layout.preferredWidth: si.px * 1.6; thickness: 2
                       fraction: si.fraction; color: si.levelColor }
        }
    }
    // Hardware glyph tinted with the base colour, filled up (or sideways) with the fill colour
    Component { id: iconC
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Item {
                id: gl
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: si.glyphW; implicitHeight: si.glyphH
                readonly property bool up: si.cfg.fillDirection !== "side"
                readonly property url src: Qt.resolvedUrl("../icons/glyphs/" + si.glyph + ".svg")
                Kirigami.Icon { anchors.fill: parent; source: gl.src; isMask: true; color: si.cfg.iconColor }
                Item {
                    clip: true
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: gl.up ? gl.width : Math.round(gl.width * si.fraction)
                    height: gl.up ? Math.round(gl.height * si.fraction) : gl.height
                    Kirigami.Icon {
                        width: gl.width; height: gl.height
                        x: 0; y: parent.height - gl.height
                        source: gl.src; isMask: true; color: si.fillColor
                    }
                }
            }
            ValueLabel { host: si }
        }
    }
    Component { id: textC
        ValueLabel { host: si; color: si.levelColor; font.pixelSize: Math.round(Math.max(10, si.px * 0.45)) }
    }

    PlasmaComponents.Label {
        visible: si.cfg.showName && !si.inPanel && si.sensorName.length > 0
        Layout.row: 2
        Layout.column: 0
        Layout.columnSpan: 2
        text: si.sensorName
        color: si.fg
        opacity: 0.7
        elide: Text.ElideRight
        font.pixelSize: Math.round(Math.max(9, (si.cfg.fontSize > 0 ? si.cfg.fontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.85))
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: Math.max(si.px * 1.6, 60)
    }
}
