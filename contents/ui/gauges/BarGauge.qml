import QtQuick

// Horizontal bar. `thickness` makes it either a "top bar" (thick) or a "progress line" (thin).
Item {
    id: root
    property real fraction: 0
    property color color: "red"
    property color trackColor: Qt.rgba(1, 1, 1, 0.15)
    property real thickness: 6

    implicitHeight: thickness

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }
    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.fraction))
        height: parent.height
        radius: height / 2
        color: root.color
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
}
