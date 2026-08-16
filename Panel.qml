import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.japetheape.keepassxc"
  ipcTarget: moduleName

  property bool installed: true
  property string windowState: "stopped"
  readonly property string pluginPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/" + moduleName
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var trayItem: findTrayItem()
  readonly property var keepassToplevel: findToplevel()
  readonly property string state: {
    if (!trayItem) return windowState
    var menuState = Model.stateForMenu(menuOpener.children)
    return menuState === "running" ? Model.stateForItem(trayItem) : menuState
  }
  readonly property string stateLabel: Model.stateLabel(state, installed)
  readonly property string stateIcon: Model.iconForState(state, installed)

  function findTrayItem() {
    var values = SystemTray.items.values
    for (var i = 0; i < values.length; i++) {
      if (Model.isKeePassXCItem(values[i])) return values[i]
    }
    return null
  }

  function findToplevel() {
    var values = ToplevelManager.toplevels.values
    for (var i = 0; i < values.length; i++) {
      if (Model.isKeePassXCToplevel(values[i])) return values[i]
    }
    return null
  }

  function launchOrFocus() {
    if (installed) Quickshell.execDetached(["bash", pluginPath + "/launch.sh"])
    close()
  }

  function lockDatabases() {
    if (!installed) return
    Quickshell.execDetached(["bash", pluginPath + "/lock.sh"])
    close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Process {
    id: availabilityCheck
    command: ["sh", "-lc", "command -v keepassxc >/dev/null 2>&1"]
    running: true
    onExited: function(exitCode) { root.installed = exitCode === 0 }
  }

  Process {
    id: statusCheck
    command: ["bash", root.pluginPath + "/status.sh"]
    running: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text || "").trim()
        root.windowState = next === "locked" || next === "unlocked" || next === "running" ? next : "stopped"
      }
    }
  }

  Timer {
    interval: 3000
    repeat: true
    running: true
    onTriggered: if (!root.trayItem && !statusCheck.running) statusCheck.running = true
  }

  QsMenuOpener {
    id: menuOpener
    menu: root.trayItem ? root.trayItem.menu : null
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.stateIcon
    active: root.state === "unlocked"
    useActiveColor: true

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.launchOrFocus()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(500))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.launchOrFocus()
      onTextKey: function(value) {
        if (value === "o" || value === "O") root.launchOrFocus()
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: content
          width: parent.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: "KeePassXC"
            meta: root.stateLabel
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: root.installed ? 1.0 : 0.5
            iconComponent: Component {
              Text {
                text: root.stateIcon
                color: root.state === "unlocked" ? Color.accent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          Text {
            visible: !root.installed
            width: parent.width
            text: "Install KeePassXC to use this widget."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          ActionRow {
            width: parent.width
            label: root.trayItem || root.keepassToplevel ? "Open KeePassXC" : "Launch KeePassXC"
            detail: root.trayItem || root.keepassToplevel ? "Show the running application" : "Start the password manager"
            iconText: "\uf084"
            enabled: root.installed
            onTriggered: root.launchOrFocus()
          }

          ActionRow {
            visible: root.state === "unlocked"
            width: parent.width
            label: "Lock all databases"
            detail: "Ask KeePassXC to lock immediately"
            iconText: "\uf023"
            enabled: root.installed
            onTriggered: root.lockDatabases()
          }

          PanelSeparator {
            visible: root.trayItem && root.trayItem.menu
            foreground: root.foreground
          }

          PanelSectionHeader {
            visible: root.trayItem && root.trayItem.menu
            text: "KEEPASSXC ACTIONS"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Column {
            visible: root.trayItem && root.trayItem.menu
            width: parent.width
            spacing: Style.space(2)

            Repeater {
              model: menuOpener.children

              delegate: Item {
                id: nativeRow
                required property var modelData
                required property int index
                readonly property bool hiddenTitle: Model.isRootTitle(modelData, index, root.trayItem)
                readonly property bool hiddenEntry: hiddenTitle || modelData.hasChildren

                visible: !hiddenEntry
                width: parent.width
                implicitHeight: hiddenEntry ? 0 : (modelData.isSeparator ? Style.space(10) : Style.space(40))

                Rectangle {
                  visible: nativeRow.modelData.isSeparator
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  height: 1
                  color: root.dim
                  opacity: 0.5
                }

                CursorSurface {
                  visible: !nativeRow.modelData.isSeparator
                  anchors.fill: parent
                  foreground: root.foreground
                  opacity: nativeRow.modelData.enabled ? 1.0 : 0.45

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(10)
                    anchors.rightMargin: Style.space(10)
                    spacing: Style.space(8)

                    Text {
                      visible: nativeRow.modelData.buttonType !== QsMenuButtonType.None
                      text: nativeRow.modelData.checkState === Qt.Checked ? "\uf00c" : ""
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      Layout.preferredWidth: Style.space(14)
                    }

                    Text {
                      Layout.fillWidth: true
                      text: String(nativeRow.modelData.text || "")
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      elide: Text.ElideRight
                    }

                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: nativeRow.modelData.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      nativeRow.modelData.triggered()
                      root.close()
                    }
                  }
                }
              }
            }
          }

          Text {
            visible: root.trayItem && !root.trayItem.menu
            width: parent.width
            text: "KeePassXC is running but did not publish tray actions."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  component ActionRow: CursorSurface {
    id: actionRow
    signal triggered()
    property string label: ""
    property string detail: ""
    property string iconText: ""

    foreground: root.foreground
    bordered: true
    implicitHeight: row.implicitHeight + Style.space(18)

    MouseArea {
      anchors.fill: parent
      enabled: actionRow.enabled
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: actionRow.triggered()
    }

    RowLayout {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(10)

      Text {
        text: actionRow.iconText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          Layout.fillWidth: true
          text: actionRow.label
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: actionRow.detail
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
