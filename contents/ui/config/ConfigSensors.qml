import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kitemmodels as KItemModels
import org.kde.ksysguard.sensors as Sensors
import "../Tags.js" as Tags

KCM.ScrollViewKCM {
    id: page
    property string cfg_sensors
    property string cfg_sensorsDefault

    property var selected: JSON.parse(cfg_sensors || "[]")
    function isSelected(id) { return selected.some(s => s.sensorId === id); }
    function tagOf(id) { const s = selected.find(s => s.sensorId === id); return s ? (s.tag ?? "") : ""; }
    function setTag(id, tag) {
        selected = selected.map(s => s.sensorId === id ? Object.assign({}, s, { tag: tag }) : s);
        cfg_sensors = JSON.stringify(selected);
    }
    function iconOf(id) { const s = selected.find(s => s.sensorId === id); return s ? (s.icon ?? "auto") : "auto"; }
    function setIcon(id, icon) {
        selected = selected.map(s => s.sensorId === id ? Object.assign({}, s, { icon: icon }) : s);
        cfg_sensors = JSON.stringify(selected);
    }
    function autoTag(id, name) { return Tags.autoTag(id, name); }
    function toggle(id, name, on) {
        let list = selected.filter(s => s.sensorId !== id);
        if (on) list.push({ sensorId: id, name: name, tag: autoTag(id, name) });
        selected = list;
        cfg_sensors = JSON.stringify(list);
    }

    Sensors.SensorTreeModel { id: treeModel }
    KItemModels.KDescendantsProxyModel { id: flatModel; model: treeModel }
    KItemModels.KSortFilterProxyModel {
        id: sensorModel
        sourceModel: flatModel
        filterRowCallback: (row, parent) => {
            const idx = sourceModel.index(row, 0);
            const id = sourceModel.data(idx, Sensors.SensorTreeModel.SensorId);
            const disp = sourceModel.data(idx, Qt.DisplayRole);
            // CPU total/per-core usage, memory and swap, disk usage (percent and amount)
            return /^cpu\/(all|cpu\d+)\/usage$/.test(id)
                || /^memory\/(physical|swap)\/(used|usedPercent|free|freePercent)$/.test(id)
                || /^memory\/physical\/(application|applicationPercent|cache|cachePercent)$/.test(id)
                || /^disk\/[^\/]+\/(used|usedPercent|free|freePercent)$/.test(id);
        }
    }

    // "Category / Subcategory: Sensor" label
    function labelFor(row) {
        const pidx = sensorModel.index(row, 0);
        let name = sensorModel.data(pidx, Qt.DisplayRole);
        let c = flatModel.mapToSource(sensorModel.mapToSource(pidx));
        let sub = null;
        while (c.parent.valid) { sub = c; c = c.parent; }
        const section = treeModel.data(c, Qt.DisplayRole);
        if (sub && /^(lmsensors|disk)\//.test(sensorModel.data(pidx, Sensors.SensorTreeModel.SensorId)))
            name = treeModel.data(sub, Qt.DisplayRole) + ": " + name;
        return { name: name, section: section };
    }

    header: Kirigami.InlineMessage {
        visible: true
        text: i18n("Tick the usage sensors to show (CPU, memory, swap, disks). Sensors come from KSysGuard. Change their order on the Order page.")
    }

    // Sensors saved in the config that are not in the live list (e.g. dGPU switched off via envycontrol / MUX).
    // They stay saved and hidden on the panel; evaluated when the model (re)fills, i.e. once per config open.
    readonly property var missing: {
        sensorModel.count;
        const present = new Set();
        for (let i = 0; i < sensorModel.count; i++)
            present.add(sensorModel.data(sensorModel.index(i, 0), Sensors.SensorTreeModel.SensorId));
        return selected.filter(s => !present.has(s.sensorId));
    }

    view: ListView {
        model: sensorModel
        clip: true
        footer: ColumnLayout {
            width: ListView.view.width
            visible: page.missing.length > 0
            Kirigami.Heading { level: 4; text: i18n("Saved but currently unavailable (kept, hidden on the panel)") }
            Repeater {
                model: page.missing
                QQC2.CheckDelegate {
                    required property var modelData
                    Layout.fillWidth: true
                    checked: true
                    text: (modelData.tag ? modelData.tag + " — " : "") + modelData.name + "   (" + modelData.sensorId + ")"
                    onToggled: page.toggle(modelData.sensorId, modelData.name, checked)
                }
            }
        }
        section.property: "dummy"
        delegate: QQC2.CheckDelegate {
            required property int index
            readonly property var info: page.labelFor(index)
            readonly property string sid: sensorModel.data(sensorModel.index(index, 0), Sensors.SensorTreeModel.SensorId)
            width: ListView.view.width
            checked: page.isSelected(sid)
            onToggled: page.toggle(sid, info.name, checked)

            // Live probe, exists only while this config window is open
            Sensors.Sensor { id: probe; sensorId: sid; updateRateLimit: 1000 }
            readonly property bool active: probe.value !== undefined && !isNaN(Number(probe.value))

            contentItem: ColumnLayout {
                spacing: 0
                QQC2.Label { text: info.section + " — " + info.name; Layout.fillWidth: true; elide: Text.ElideRight }
                RowLayout {
                    visible: checked
                    QQC2.Label { text: i18n("Tag:"); font: Kirigami.Theme.smallFont }
                    QQC2.TextField {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        maximumLength: 12
                        placeholderText: page.autoTag(sid, info.name)
                        text: page.tagOf(sid)
                        onTextEdited: page.setTag(sid, text)
                    }
                    QQC2.Label { text: i18n("Icon:"); font: Kirigami.Theme.smallFont }
                    QQC2.ComboBox {
                        id: iconBox
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                        textRole: "text"; valueRole: "value"
                        model: [{ text: i18n("Auto (%1)", Tags.autoIcon(sid, info.name)), value: "auto" }]
                                   .concat(Tags.glyphs.map(g => ({ text: g, value: g })))
                        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.iconOf(sid)))
                        onActivated: page.setIcon(sid, currentValue)
                        delegate: QQC2.ItemDelegate {
                            required property var modelData
                            width: iconBox.width
                            highlighted: iconBox.highlightedIndex === index
                            contentItem: RowLayout {
                                Kirigami.Icon {
                                    visible: modelData.value !== "auto"
                                    source: Qt.resolvedUrl("../../icons/glyphs/" + modelData.value + ".svg")
                                    isMask: true; color: Kirigami.Theme.textColor
                                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                }
                                QQC2.Label { text: modelData.text; Layout.fillWidth: true }
                            }
                        }
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    font: Kirigami.Theme.smallFont
                    color: active ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                    text: (active ? i18n("● Active: %1", Tags.isBytes(sid) ? Tags.formatBytes(Number(probe.value)) : Number(probe.value).toFixed(1) + " %") : i18n("○ No data")) + "   (" + sid + ")"
                    elide: Text.ElideRight
                }
            }
        }
    }
}
