.pragma library

// Settings a preset stores: name -> type (s = string, b = bool, i = int, c = colour)
var keys = {
    displayMode: "s", showTag: "b", tagPosition: "s", itemSpacing: "i", outerPadding: "i", tagSpacing: "i",
    iconColor: "c", fillColorMode: "s", fillColor: "c", fillDirection: "s",
    showValue: "b", valuePosition: "s", valueSpacing: "i", valueFontSize: "i", valueCorner: "s",
    showName: "b", updateRate: "i", thresholds: "s", levelColors: "s",
    useCustomTextColor: "b", textColor: "c", fontSize: "i", gaugeSize: "i"
};

function coerce(type, v) {
    if (type === "b") return v === true || v === "true";
    if (type === "i") { const n = Math.round(Number(v)); return isNaN(n) ? undefined : n; }
    if (type === "c") return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(String(v)) ? String(v) : undefined;
    return v === null || v === undefined ? undefined : String(v);
}

// Validate a decoded preset: keep only known settings with the right type
function sanitize(obj) {
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) throw new Error("expected a mapping at the top level");
    const out = { name: obj.name ? String(obj.name) : "Imported preset", settings: {} };
    const src = obj.settings || {};
    for (const k in keys) {
        if (src[k] === undefined) continue;
        const v = coerce(keys[k], src[k]);
        if (v !== undefined) out.settings[k] = v;
    }
    if (Array.isArray(obj.sensors)) {
        out.sensors = obj.sensors.filter(s => s && typeof s === "object" && s.sensorId).map(s => {
            const r = { sensorId: String(s.sensorId), name: String(s.name ?? s.sensorId) };
            if (s.tag !== undefined && s.tag !== null) r.tag = String(s.tag);
            if (s.icon) r.icon = String(s.icon);
            return r;
        });
    }
    if (Object.keys(out.settings).length === 0 && !out.sensors) throw new Error("no known settings or sensors found");
    return out;
}

// ---- YAML (the small subset used for presets: maps, lists, scalars) ----
function scalarOut(v) {
    if (typeof v === "boolean" || typeof v === "number") return String(v);
    return JSON.stringify(String(v));   // JSON strings are valid YAML double-quoted scalars
}

function toYaml(p) {
    let y = "# Usage Peek preset\nname: " + scalarOut(p.name) + "\nsettings:\n";
    for (const k in keys) if (p.settings[k] !== undefined) y += "  " + k + ": " + scalarOut(p.settings[k]) + "\n";
    if (p.sensors) {
        if (p.sensors.length === 0) return y + "sensors: []\n";
        y += "sensors:\n";
        for (const s of p.sensors) {
            y += "  - sensorId: " + scalarOut(s.sensorId) + "\n    name: " + scalarOut(s.name) + "\n";
            if (s.tag !== undefined) y += "    tag: " + scalarOut(s.tag) + "\n";
            if (s.icon) y += "    icon: " + scalarOut(s.icon) + "\n";
        }
    }
    return y;
}

function scalarIn(s) {
    s = s.trim();
    let m;
    if ((m = s.match(/^"((?:[^"\\]|\\.)*)"\s*(?:#.*)?$/))) return JSON.parse('"' + m[1] + '"');
    if ((m = s.match(/^'((?:[^']|'')*)'\s*(?:#.*)?$/))) return m[1].replace(/''/g, "'");
    s = s.replace(/\s+#.*$/, "");
    if (s === "[]") return [];
    if (s === "true") return true;
    if (s === "false") return false;
    if (s === "null" || s === "~" || s === "") return null;
    if (/^-?\d+$/.test(s)) return Number(s);
    return s;
}

function parseYaml(text) {
    const lines = [];
    for (const raw of text.replace(/\r/g, "").split("\n")) {
        if (/^\s*(#.*)?$/.test(raw)) continue;
        if (raw.indexOf("\t") >= 0 && /^\s*\t/.test(raw)) throw new Error("tabs are not allowed for indentation");
        lines.push({ indent: raw.match(/^ */)[0].length, text: raw.trim() });
    }
    let pos = 0;
    const isSeq = l => l.text === "-" || l.text.startsWith("- ");
    function block(indent) { return isSeq(lines[pos]) ? seq(indent) : map(indent); }
    function map(indent) {
        const obj = {};
        while (pos < lines.length && lines[pos].indent === indent && !isSeq(lines[pos])) {
            const m = lines[pos].text.match(/^("(?:[^"\\]|\\.)*"|[^:]+?):(?:\s+(.*))?$/);
            if (!m) throw new Error("cannot read line: " + lines[pos].text);
            const key = m[1].startsWith('"') ? JSON.parse(m[1]) : m[1].trim();
            pos++;
            if (m[2] === undefined || m[2].trim() === "")
                obj[key] = pos < lines.length && lines[pos].indent > indent ? block(lines[pos].indent) : null;
            else obj[key] = scalarIn(m[2]);
        }
        return obj;
    }
    function seq(indent) {
        const arr = [];
        while (pos < lines.length && lines[pos].indent === indent && isSeq(lines[pos])) {
            const rest = lines[pos].text.slice(1).replace(/^\s+/, "");
            const col = indent + (lines[pos].text.length - rest.length);
            if (rest === "") {
                pos++;
                arr.push(pos < lines.length && lines[pos].indent > indent ? block(lines[pos].indent) : null);
            } else if (/^("(?:[^"\\]|\\.)*"|[^"'\s\[][^:]*?):(\s|$)/.test(rest)) {
                lines[pos] = { indent: col, text: rest };   // "- key: v" opens a mapping at the column after the dash
                arr.push(map(col));
            } else { arr.push(scalarIn(rest)); pos++; }
        }
        return arr;
    }
    if (lines.length === 0) throw new Error("the file is empty");
    const result = block(lines[0].indent);
    if (pos < lines.length) throw new Error("unexpected content: " + lines[pos].text);
    return result;
}

function fromYaml(text) { return sanitize(parseYaml(text)); }
