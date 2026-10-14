import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.ScrollViewKCM {
    id: page
    property string cfg_sensors
    property string cfg_sensorsDefault

    // Panel order = order of the saved list
    property var selected: JSON.parse(cfg_sensors || "[]")
    onCfg_sensorsChanged: selected = JSON.parse(cfg_sensors || "[]")
    function move(i, delta) {
        const j = i + delta;
        if (j < 0 || j >= selected.length) return;
        let list = selected.slice();
        [list[i], list[j]] = [list[j], list[i]];
        selected = list;
        cfg_sensors = JSON.stringify(list);
    }

    header: Kirigami.InlineMessage {
        visible: true
        text: page.selected.length > 0 ? i18n("Order of the sensors on the panel (first = left / top).")
                                       : i18n("No sensors selected yet. Pick some on the Sensors page and press Apply.")
    }

    view: ListView {
        model: page.selected
        clip: true
        delegate: QQC2.ItemDelegate {
            required property int index
            required property var modelData
            width: ListView.view.width
            contentItem: RowLayout {
                QQC2.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: (index + 1) + ".  " + (modelData.tag ? modelData.tag + " — " : "") + modelData.name
                }
                QQC2.ToolButton { icon.name: "go-up";   enabled: index > 0
                                  onClicked: page.move(index, -1) }
                QQC2.ToolButton { icon.name: "go-down"; enabled: index < page.selected.length - 1
                                  onClicked: page.move(index, 1) }
            }
        }
    }
}
