import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQC

KCM.SimpleKCM {
    id: page
    property string cfg_displayMode
    property bool   cfg_showTag
    property color  cfg_iconColor
    property string cfg_fillColorMode
    property color  cfg_fillColor
    property string cfg_fillDirection
    property string cfg_tagPosition
    property bool   cfg_showValue
    property string cfg_valuePosition
    property int    cfg_itemSpacing
    property int    cfg_tagSpacing
    property int    cfg_valueSpacing
    property string cfg_valueCorner
    property bool   cfg_showName
    property int    cfg_updateRate
    property string cfg_thresholds
    property string cfg_levelColors
    property bool   cfg_useCustomTextColor
    property color  cfg_textColor
    property int    cfg_fontSize
    property int    cfg_gaugeSize

    property var colors: (cfg_levelColors || "").split(",")
    function setColor(i, c) { let a = colors.slice(); a[i] = String(c); cfg_levelColors = a.join(","); }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Display mode:")
            textRole: "text"; valueRole: "value"
            model: [
                { text: i18n("Circle gauge"),  value: "circle" },
                { text: i18n("Top bar"),       value: "topbar" },
                { text: i18n("Progress line"), value: "line" },
                { text: i18n("Icon (CPU, RAM, drive…)"), value: "icon" },
                { text: i18n("Text only"),     value: "text" }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_displayMode))
            onActivated: page.cfg_displayMode = currentValue
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Icon style")
                             visible: page.cfg_displayMode === "icon" }
        KQC.ColorButton { Kirigami.FormData.label: i18n("Icon colour:"); visible: page.cfg_displayMode === "icon"
                          color: page.cfg_iconColor; onColorChanged: page.cfg_iconColor = color }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Fill colour:"); visible: page.cfg_displayMode === "icon"
            textRole: "text"; valueRole: "value"
            model: [ { text: i18n("By usage level"), value: "level" }, { text: i18n("Custom"), value: "custom" } ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_fillColorMode))
            onActivated: page.cfg_fillColorMode = currentValue
        }
        KQC.ColorButton { Kirigami.FormData.label: i18n("Custom fill colour:")
                          visible: page.cfg_displayMode === "icon"; enabled: page.cfg_fillColorMode === "custom"
                          color: page.cfg_fillColor; onColorChanged: page.cfg_fillColor = color }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Fill direction:"); visible: page.cfg_displayMode === "icon"
            textRole: "text"; valueRole: "value"
            model: [ { text: i18n("Bottom to top"), value: "up" }, { text: i18n("Left to right"), value: "side" } ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_fillDirection))
            onActivated: page.cfg_fillDirection = currentValue
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("General")
                             visible: page.cfg_displayMode === "icon" }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Gauge size (px, max in panel):"); from: 16; to: 256; value: page.cfg_gaugeSize
                       onValueModified: page.cfg_gaugeSize = value }
        QQC2.CheckBox { text: i18n("Show tags (CPU, NVME1…)"); checked: page.cfg_showTag; onToggled: page.cfg_showTag = checked }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Tag position:")
            enabled: page.cfg_showTag
            textRole: "text"; valueRole: "value"
            model: [
                { text: i18n("Above"),        value: "top" },
                { text: i18n("Below"),        value: "bottom" },
                { text: i18n("Left of icon"),  value: "left" },
                { text: i18n("Right of icon"), value: "right" }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_tagPosition))
            onActivated: page.cfg_tagPosition = currentValue
        }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Space between sensors (px):"); from: 0; to: 64; value: page.cfg_itemSpacing
                       onValueModified: page.cfg_itemSpacing = value }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Space between tag and gauge (px):"); from: 0; to: 32; value: page.cfg_tagSpacing
                       enabled: page.cfg_showTag; onValueModified: page.cfg_tagSpacing = value }
        QQC2.CheckBox { text: i18n("Show value (ignored in text-only mode)"); checked: page.cfg_showValue
                        onToggled: page.cfg_showValue = checked }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Value position:")
            enabled: page.cfg_showValue
            textRole: "text"; valueRole: "value"
            model: [ { text: i18n("Below (icon / bar modes)"), value: "below" }, { text: i18n("Beside (icon / bar modes)"), value: "side" } ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_valuePosition))
            onActivated: page.cfg_valuePosition = currentValue
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Value corner (icon mode):")
            visible: page.cfg_displayMode === "icon"; enabled: page.cfg_showValue
            textRole: "text"; valueRole: "value"
            model: [
                { text: i18n("Bottom right"), value: "br" }, { text: i18n("Bottom left"), value: "bl" },
                { text: i18n("Top right"), value: "tr" },    { text: i18n("Top left"), value: "tl" }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_valueCorner))
            onActivated: page.cfg_valueCorner = currentValue
        }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Space between icon and value (px):"); from: 0; to: 64; value: page.cfg_valueSpacing
                       enabled: page.cfg_showValue; onValueModified: page.cfg_valueSpacing = value }
        QQC2.CheckBox { text: i18n("Show full sensor name (desktop only)"); checked: page.cfg_showName; onToggled: page.cfg_showName = checked }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Update every (s):"); from: 1; to: 60; value: page.cfg_updateRate
                       onValueModified: page.cfg_updateRate = value }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Text") }
        QQC2.CheckBox { text: i18n("Custom text colour"); checked: page.cfg_useCustomTextColor
                        onToggled: page.cfg_useCustomTextColor = checked }
        KQC.ColorButton { Kirigami.FormData.label: i18n("Text colour:"); enabled: page.cfg_useCustomTextColor
                          color: page.cfg_textColor; onColorChanged: page.cfg_textColor = color }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Font size (0 = default):"); from: 0; to: 96; value: page.cfg_fontSize
                       onValueModified: page.cfg_fontSize = value }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Levels") }
        QQC2.TextField { Kirigami.FormData.label: i18n("Level thresholds (%):"); text: page.cfg_thresholds
                         placeholderText: "50,70,85,95"; onTextEdited: page.cfg_thresholds = text }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Level colours") }
        Repeater {
            model: 5
            KQC.ColorButton {
                required property int index
                Kirigami.FormData.label: i18n("Level %1:", index + 1)
                color: page.colors[index] ?? "#ffffff"
                onColorChanged: page.setColor(index, color)
            }
        }
    }
}
