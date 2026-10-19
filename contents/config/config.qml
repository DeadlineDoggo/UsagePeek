import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: i18n("Sensors");    icon: "utilities-system-monitor";             source: "config/ConfigSensors.qml" }
    ConfigCategory { name: i18n("Order");      icon: Qt.resolvedUrl("../icons/order.svg");           source: "config/ConfigOrder.qml" }
    ConfigCategory { name: i18n("Appearance"); icon: "preferences-desktop-color"; source: "config/ConfigAppearance.qml" }
    ConfigCategory { name: i18n("Desktop");    icon: "preferences-desktop-display"; source: "config/ConfigDesktop.qml" }
    ConfigCategory { name: i18n("Presets");    icon: "bookmarks";                            source: "config/ConfigPresets.qml" }
}
