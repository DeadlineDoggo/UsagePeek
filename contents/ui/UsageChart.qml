import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "Tags.js" as Tags

// History graph (0-100 %) of every selected sensor, with a legend (swatch, name, current value) underneath
ColumnLayout {
    id: chart

    required property var sensors
    readonly property var cfg: Plasmoid.configuration
    readonly property int maxPoints: Math.max(10, Math.round(cfg.graphMinutes * 60 / Math.max(1, cfg.updateRate)))
    readonly property var palette: ["#3daee9", "#4cd964", "#ffa43a", "#c678dd", "#ff5a5f", "#f5e050", "#1abc9c", "#e91e63"]
    readonly property color fg: cfg.useCustomTextColor ? cfg.textColor : Kirigami.Theme.textColor
    readonly property int fontPx: cfg.fontSize > 0 ? cfg.fontSize : Kirigami.Theme.defaultFont.pixelSize

    spacing: Kirigami.Units.smallSpacing

    // Sample every sensor once per update interval, then redraw
    Timer {
        interval: Math.max(1, chart.cfg.updateRate) * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            for (let i = 0; i < rows.count; i++) {
                const r = rows.itemAt(i);
                if (!r) continue;
                const h = r.hist.slice(-(chart.maxPoints - 1));
                h.push(r.percent);
                r.hist = h;
            }
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 40
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const lm = chart.fontPx * 3.2, tm = chart.fontPx * 0.6, bm = 2;
            const pw = width - lm - 4, ph = height - tm - bm;
            if (pw <= 0 || ph <= 0) return;

            const x = k => lm + pw - (chart.maxPoints - 1 - k) * pw / (chart.maxPoints - 1);
            const y = v => tm + ph - Math.max(0, Math.min(100, v)) / 100 * ph;

            // grid + axis labels (fixed 0..100 %)
            ctx.font = Math.round(chart.fontPx * 0.8) + "px sans-serif";
            ctx.textAlign = "right"; ctx.textBaseline = "middle";
            ctx.lineWidth = 1;
            for (let s = 0; s <= 4; s++) {
                const v = s * 25, yy = Math.round(y(v)) + 0.5;
                ctx.strokeStyle = Qt.rgba(chart.fg.r, chart.fg.g, chart.fg.b, 0.15);
                ctx.beginPath(); ctx.moveTo(lm, yy); ctx.lineTo(lm + pw, yy); ctx.stroke();
                ctx.fillStyle = Qt.rgba(chart.fg.r, chart.fg.g, chart.fg.b, 0.7);
                ctx.fillText(v + "%", lm - 6, yy);
            }

            // series
            ctx.lineJoin = "round"; ctx.lineCap = "round"; ctx.lineWidth = 2;
            for (let i = 0; i < rows.count; i++) {
                const r = rows.itemAt(i);
                if (!r || r.hist.length < 2) continue;
                const off = chart.maxPoints - r.hist.length;
                const c = r.seriesColor;
                if (chart.cfg.graphFill) {
                    let started = false, firstX = 0, lastX = 0;
                    ctx.beginPath();
                    for (let k = 0; k < r.hist.length; k++) {
                        const v = r.hist[k]; if (isNaN(v)) continue;
                        const px = x(off + k);
                        if (!started) { ctx.moveTo(px, y(v)); firstX = px; started = true; } else ctx.lineTo(px, y(v));
                        lastX = px;
                    }
                    if (started) {
                        ctx.lineTo(lastX, tm + ph); ctx.lineTo(firstX, tm + ph); ctx.closePath();
                        ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.14); ctx.fill();
                    }
                }
                ctx.strokeStyle = c;
                ctx.beginPath();
                let pen = false;
                for (let k = 0; k < r.hist.length; k++) {
                    const v = r.hist[k];
                    if (isNaN(v)) { pen = false; continue; }
                    if (!pen) { ctx.moveTo(x(off + k), y(v)); pen = true; } else ctx.lineTo(x(off + k), y(v));
                }
                ctx.stroke();
            }
        }
    }

    // Legend rows: swatch, name, current value
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Repeater {
            id: rows
            model: chart.sensors
            RowLayout {
                id: row
                required property var modelData
                required property int index
                property var hist: []
                readonly property bool isBytes: Tags.isBytes(modelData.sensorId)
                readonly property real value: sensor.value === undefined || isNaN(Number(sensor.value)) ? NaN : Number(sensor.value)
                readonly property real total: totalSensor.value === undefined || isNaN(Number(totalSensor.value)) ? NaN : Number(totalSensor.value)
                // Byte sensors are plotted as a share of their total
                readonly property real percent: isNaN(value) ? NaN : isBytes ? (total > 0 ? value / total * 100 : 0) : value
                readonly property color seriesColor: chart.palette[index % chart.palette.length]
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: !isNaN(value)

                Sensors.Sensor { id: sensor; sensorId: row.modelData.sensorId; updateRateLimit: chart.cfg.updateRate * 1000 }
                Sensors.Sensor { id: totalSensor; sensorId: row.isBytes ? Tags.totalId(row.modelData.sensorId) : ""; updateRateLimit: chart.cfg.updateRate * 1000 }

                Rectangle { implicitWidth: 4; implicitHeight: chart.fontPx * 1.2; radius: 2; color: row.seriesColor }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: chart.fg
                    font.pixelSize: chart.fontPx
                    text: row.modelData.tag ? row.modelData.tag + "  " + row.modelData.name : row.modelData.name
                }
                PlasmaComponents.Label {
                    color: chart.fg
                    font.pixelSize: chart.fontPx
                    font.bold: true
                    text: isNaN(row.value) ? "–" : row.isBytes ? Tags.formatBytes(row.value) : Math.round(row.value) + "%"
                }
            }
        }
    }
}
