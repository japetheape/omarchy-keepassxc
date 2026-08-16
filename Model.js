function text(value) {
  return String(value || "").toLowerCase()
}

function itemText(item) {
  if (!item) return ""
  return [item.id, item.title, item.icon].map(text).join(" ")
}

function isKeePassXCItem(item) {
  var value = itemText(item)
  return value.indexOf("keepassxc") !== -1 || value.indexOf("keepass xc") !== -1
}

function isKeePassXCToplevel(toplevel) {
  if (!toplevel) return false
  var value = [toplevel.appId, toplevel.title].map(text).join(" ")
  return value.indexOf("keepassxc") !== -1 || value.indexOf("keepass xc") !== -1
}

function stateForItem(item) {
  if (!item) return "stopped"
  var value = [item.icon, item.iconName].map(text).join(" ")
  if (/(^|[^a-z])(?:database-)?locked([^a-z]|$)/.test(value)) return "locked"
  if (/(^|[^a-z])(?:database-)?(?:unlocked|open)([^a-z]|$)/.test(value)) return "unlocked"

  var title = text(item.tooltipTitle).trim()
  if (title === "[locked] - keepassxc") return "locked"
  if (title !== "keepassxc" && title.slice(-12) === " - keepassxc") return "unlocked"
  return "running"
}

function stateForMenu(children) {
  if (!children) return "running"
  var values = Array.isArray(children) ? children : children.values
  if (!values) return "running"

  for (var i = 0; i < values.length; i++) {
    var entry = values[i]
    if (!entry || entry.isSeparator) continue
    var value = text(entry.text).split("&").join("").trim()
    if (value === "lock databases") return entry.enabled ? "unlocked" : "locked"
    if (value === "unlock database" || value === "unlock databases") return "locked"
  }

  return "running"
}

function stateLabel(state, installed) {
  if (!installed) return "KeePassXC is not installed"
  if (state === "stopped") return "KeePassXC is not running"
  if (state === "unlocked") return "Database unlocked"
  if (state === "locked") return "Database locked"
  return "KeePassXC is running"
}

function iconForState(state, installed) {
  if (!installed) return "\uf071"
  if (state === "unlocked") return "\uf09c"
  if (state === "locked") return "\uf023"
  return "\uf084"
}

function isRootTitle(entry, index, item) {
  if (!entry || index !== 0 || !entry.hasChildren || !item) return false
  return text(entry.text) === text(item.title || item.id)
}

if (typeof module !== "undefined") {
  module.exports = {
    itemText: itemText,
    isKeePassXCItem: isKeePassXCItem,
    isKeePassXCToplevel: isKeePassXCToplevel,
    stateForItem: stateForItem,
    stateForMenu: stateForMenu,
    stateLabel: stateLabel,
    iconForState: iconForState,
    isRootTitle: isRootTitle
  }
}
