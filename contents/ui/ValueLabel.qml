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
    Layout.alignment: Qt.AlignHCenter
}
