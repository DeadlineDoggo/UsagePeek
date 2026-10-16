import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.Label {
    required property var host   // the owning SensorItem

    visible: host.cfg.showValue || host.cfg.displayMode === "text"
    text: host.valueText
    color: host.fg
    font.pixelSize: host.cfg.fontSize > 0 ? host.cfg.fontSize : Kirigami.Theme.defaultFont.pixelSize
    font.bold: true
    Layout.alignment: Qt.AlignCenter
    // Reserve the width of three digits so the layout doesn't jump between 5%, 42% and 100%
    horizontalAlignment: Text.AlignHCenter
    Layout.preferredWidth: Math.max(implicitWidth, host.isBytes ? 0 : widest.advanceWidth)
    TextMetrics { id: widest; font: parent.font; text: "100%" }
}
