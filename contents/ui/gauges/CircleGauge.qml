import QtQuick

Canvas {
    id: root
    property real fraction: 0
    property color color: "red"
    property color trackColor: Qt.rgba(1, 1, 1, 0.15)
    property real lineWidth: Math.max(3, width * 0.1)

    onFractionChanged: requestPaint()
    onColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const c = width / 2, r = c - lineWidth / 2;
        const start = Math.PI * 0.75, span = Math.PI * 1.5;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.strokeStyle = trackColor;
        ctx.beginPath(); ctx.arc(c, c, r, start, start + span); ctx.stroke();
        if (fraction > 0) {
            ctx.strokeStyle = color;
            ctx.beginPath(); ctx.arc(c, c, r, start, start + span * fraction); ctx.stroke();
        }
    }
}
