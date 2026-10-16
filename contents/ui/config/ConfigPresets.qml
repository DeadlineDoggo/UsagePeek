import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support
import "../Presets.js" as Presets

KCM.SimpleKCM {
    id: page
    property string cfg_presets
    property string cfg_sensors
    property string cfg_displayMode
    property bool   cfg_showTag
    property string cfg_tagPosition
    property int    cfg_itemSpacing
    property int    cfg_tagSpacing
    property color  cfg_iconColor
    property string cfg_fillColorMode
    property color  cfg_fillColor
    property string cfg_fillDirection
    property bool   cfg_showValue
    property string cfg_valuePosition
    property int    cfg_valueSpacing
    property int    cfg_valueFontSize
    property string cfg_valueCorner
    property bool   cfg_showName
    property int    cfg_updateRate
    property string cfg_thresholds
    property string cfg_levelColors
    property bool   cfg_useCustomTextColor
    property color  cfg_textColor
    property int    cfg_fontSize
    property int    cfg_gaugeSize

    property var presets: JSON.parse(cfg_presets || "[]")
    onCfg_presetsChanged: presets = JSON.parse(cfg_presets || "[]")
    property string statusText: ""
    property bool statusError: false
    property var pendingExport: null

    function say(text, error) { statusText = text; statusError = !!error; }

    // Snapshot of the saved configuration (press Apply on the other pages first)
    function snapshot(name, withSensors) {
        const p = { name: name, settings: {} };
        for (const k in Presets.keys) p.settings[k] = Presets.keys[k] === "c" ? String(page["cfg_" + k]) : page["cfg_" + k];
        if (withSensors) p.sensors = JSON.parse(cfg_sensors || "[]");
        return p;
    }
    function store(list) { presets = list; cfg_presets = JSON.stringify(list); }
    function savePreset(name, withSensors) {
        name = name.trim();
        if (name.length === 0) { say(i18n("Give the preset a name first."), true); return; }
        const p = snapshot(name, withSensors);
        const i = presets.findIndex(x => x.name === name);
        let list = presets.slice();
        if (i >= 0) list[i] = p; else list.push(p);
        store(list);
        say(i18n("Preset \"%1\" saved. Press Apply to keep it.", name), false);
    }
    function loadPreset(p) {
        for (const k in Presets.keys) if (p.settings[k] !== undefined) page["cfg_" + k] = p.settings[k];
        if (p.sensors) cfg_sensors = JSON.stringify(p.sensors);
        say(i18n("Preset \"%1\" loaded. Press Apply to use it.", p.name), false);
    }
    function removePreset(i) { store(presets.filter((_, j) => j !== i)); }

    // ---- file access through the shell (QML itself cannot write files) ----
    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }
    function pathOf(url) { return decodeURIComponent(String(url).replace(/^file:\/\//, "")); }
    property int runId: 0
    property var callbacks: ({})
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            const cb = page.callbacks[source];
            delete page.callbacks[source];
            if (cb) cb(data["exit code"] === 0, String(data["stdout"] ?? ""), String(data["stderr"] ?? ""));
        }
    }
    function run(cmd, cb) {
        const src = cmd + " # " + (++runId);
        callbacks[src] = cb;
        exec.connectSource(src);
    }

    function exportTo(path, p) {
        run("printf %s " + shq(Presets.toYaml(p)) + " > " + shq(path), (ok, out, err) =>
            say(ok ? i18n("Exported \"%1\" to %2", p.name, path) : i18n("Export failed: %1", err), !ok));
    }
    function importFrom(path) {
        run("cat " + shq(path), (ok, out, err) => {
            if (!ok) { say(i18n("Could not read the file: %1", err), true); return; }
            try {
                const p = Presets.fromYaml(out);
                let list = presets.filter(x => x.name !== p.name);
                list.push(p);
                store(list);
                say(i18n("Imported preset \"%1\". Press Apply to keep it.", p.name), false);
            } catch (e) { say(i18n("Not a valid preset file: %1", e.message), true); }
        });
    }

    FileDialog {
        id: exportDialog
        fileMode: FileDialog.SaveFile
        title: i18n("Export preset")
        nameFilters: [i18n("YAML files (*.yaml *.yml)")]
        defaultSuffix: "yaml"
        onAccepted: if (page.pendingExport) page.exportTo(page.pathOf(selectedFile), page.pendingExport)
    }
    FileDialog {
        id: importDialog
        fileMode: FileDialog.OpenFile
        title: i18n("Import preset")
        nameFilters: [i18n("YAML files (*.yaml *.yml)"), i18n("All files (*)")]
        onAccepted: page.importFrom(page.pathOf(selectedFile))
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Information
            text: i18n("A preset stores the appearance settings (and optionally the sensor list). Apply your changes on the other pages before saving one.")
        }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.statusText.length > 0
            type: page.statusError ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
            text: page.statusText
        }

        Kirigami.Heading { level: 3; text: i18n("Save current settings") }
        RowLayout {
            Layout.fillWidth: true
            QQC2.TextField { id: nameField; Layout.fillWidth: true; placeholderText: i18n("Preset name") }
            QQC2.CheckBox { id: withSensors; text: i18n("Include sensors"); checked: true }
            QQC2.Button { icon.name: "document-save"; text: i18n("Save"); onClicked: page.savePreset(nameField.text, withSensors.checked) }
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading { level: 3; text: i18n("Your presets"); Layout.fillWidth: true }
            QQC2.Button { icon.name: "document-import"; text: i18n("Import YAML…"); onClicked: importDialog.open() }
        }
        QQC2.Label {
            visible: page.presets.length === 0
            opacity: 0.7
            text: i18n("No presets yet.")
        }
        Repeater {
            model: page.presets
            delegate: Kirigami.AbstractCard {
                required property int index
                required property var modelData
                Layout.fillWidth: true
                contentItem: RowLayout {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        QQC2.Label { text: modelData.name; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                        QQC2.Label {
                            opacity: 0.7
                            font: Kirigami.Theme.smallFont
                            text: (modelData.settings.displayMode ? i18n("Mode: %1", modelData.settings.displayMode) : "")
                                  + (modelData.sensors ? "  ·  " + i18np("%1 sensor", "%1 sensors", modelData.sensors.length) : "")
                        }
                    }
                    QQC2.Button { text: i18n("Load"); icon.name: "document-open"; onClicked: page.loadPreset(modelData) }
                    QQC2.ToolButton { icon.name: "document-export"; QQC2.ToolTip.text: i18n("Export to YAML…"); QQC2.ToolTip.visible: hovered
                                      onClicked: { page.pendingExport = modelData; exportDialog.open() } }
                    QQC2.ToolButton { icon.name: "edit-delete"; QQC2.ToolTip.text: i18n("Delete"); QQC2.ToolTip.visible: hovered
                                      onClicked: page.removePreset(index) }
                }
            }
        }
    }
}
