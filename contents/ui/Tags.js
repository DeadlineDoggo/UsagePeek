.pragma library

// Suggest a short tag: CPU, C1.., RAM, SWAP, disk name…
function autoTag(id, name) {
    let m;
    if (id.startsWith("cpu/all")) return "CPU";
    if ((m = id.match(/^cpu\/cpu(\d+)\//))) return "C" + (Number(m[1]) + 1);
    if (id.startsWith("memory/physical")) return "RAM";
    if (id.startsWith("memory/swap")) return "SWAP";
    if (id.startsWith("disk/all")) return "DISKS";
    if (id.startsWith("disk/")) return diskName(name).toUpperCase().slice(0, 6);
    return name.split(/[ :]/)[0].toUpperCase().slice(0, 6);
}

// "Root: Percentage Used" -> "Root"
function diskName(name) {
    const i = name.indexOf(":");
    return (i > 0 ? name.slice(0, i) : name).trim();
}

// Glyph names (contents/icons/glyphs/glyph-<name>.svg), in the order shown in the pickers
var glyphs = ["cpu", "ram", "swap", "hdd", "ssd", "nvme", "disk", "bolt", "unknown", "point"];

// Guess the glyph for a sensor
function autoIcon(id, name) {
    if (id.startsWith("cpu/")) return "cpu";
    if (id.startsWith("memory/swap")) return "swap";
    if (id.startsWith("memory/")) return "ram";
    if (id.startsWith("disk/")) {
        if (/nvme/i.test(id + name)) return "nvme";
        if (/ssd/i.test(name)) return "ssd";
        return "disk";
    }
    return "unknown";
}

// Sensors reporting a byte amount (everything else under memory/ and disk/ is a percentage)
function isBytes(id) {
    return /^(memory\/(physical|swap)|disk\/[^\/]+)\/(used|free|application|buffer|cache|total)$/.test(id);
}

// For a byte sensor, the sensor holding the total (to draw the fill level)
function totalId(id) {
    return id.replace(/\/[^\/]+$/, "/total");
}

function formatBytes(b) {
    const u = ["B", "KB", "MB", "GB", "TB"];
    let i = 0;
    while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
    return (b >= 100 || i === 0 ? Math.round(b) : b.toFixed(1)) + " " + u[i];
}

// width / height of each glyph
var glyphAspect = {
    "cpu": 1, "ram": 2, "swap": 1, "hdd": 0.923, "ssd": 0.815, "nvme": 2.071, "disk": 1.556,
    "bolt": 0.759, "unknown": 1, "point": 1
};
