import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ShellRoot {
    id: root

    // Font families
    property string iconFont: "Symbols Nerd Font"
    property string textFont: "Segoe UI"

    // Colors
    property color accentColor: "#0078d4"
    property color surfaceColor: "#202020"
    property color surfaceAlt: "#2d2d2d"
    property color surfaceHover: "#383838"
    property color borderColor: "#404040"
    property color textColor: "#ffffff"
    property color textSecondary: "#999999"
    property color warningColor: "#ffcc4a"

    // System properties
    property int volume: 50
    property bool volumeMuted: false
    property int brightness: 75
    property bool isCharging: false
    property int batteryLevel: 85
    property real cpuUsage: 0
    property real ramUsage: 0
    property string powerProfile: "balanced"
    property bool bluetoothEnabled: true
    property bool nightLightEnabled: false
    property bool naturalScroll: false
    property bool followMouse: true

    // Process monitors
    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"]
        running: false
        stdout: SplitParser { onRead: d => root.cpuUsage = parseFloat(d) || 0 }
    }

    Process {
        id: ramProc
        command: ["bash", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'"]
        running: false
        stdout: SplitParser { onRead: d => root.ramUsage = parseFloat(d) || 0 }
    }

    Process {
        id: profileProc
        command: ["bash", "-c", "powerprofilesctl get"]
        running: false
        stdout: SplitParser { onRead: d => root.powerProfile = d.trim() || "balanced" }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: { cpuProc.running = true; ramProc.running = true; profileProc.running = true }
    }

    // IPC Handlers
    IpcHandler {
        target: "shell"
        function toggleStartMenu() {
            startMenu.visible = !startMenu.visible
            if (startMenu.visible) { actionCenter.visible = false; widgetsPanel.visible = false }
        }
        function toggleActionCenter() {
            actionCenter.visible = !actionCenter.visible
            if (actionCenter.visible) { startMenu.visible = false; widgetsPanel.visible = false }
        }
        function toggleWidgets() {
            widgetsPanel.visible = !widgetsPanel.visible
            if (widgetsPanel.visible) { startMenu.visible = false; actionCenter.visible = false }
        }
        function togglePowerMenu() { powerMenu.visible = !powerMenu.visible }
        function togglePopupPowerMenu() { popupPowerMenu.toggle() }
        function toggleSettings() { settingsPanel.visible = !settingsPanel.visible; if (settingsPanel.visible) root.closeAllPanels() }
        function toggleOverview() {
            workspaceOverview.visible = !workspaceOverview.visible
            if (workspaceOverview.visible) {
                startMenu.visible = false
                actionCenter.visible = false
                widgetsPanel.visible = false
                allAppsPanel.visible = false
            }
        }
        function showDesktop() { Hyprland.dispatch("togglespecialworkspace") }
        function lockScreen() { Quickshell.execDetached(["hyprlock"]) }
        function logout() { Hyprland.dispatch("exit") }
        function suspend() { Quickshell.execDetached(["systemctl", "suspend"]) }
        function reboot() { Quickshell.execDetached(["systemctl", "reboot"]) }
        function shutdown() { Quickshell.execDetached(["systemctl", "poweroff"]) }
        function closePanels() { root.closeAllPanels() }
        function toggleWallpaperSelector() { wallpaperSelector.toggle() }
    }

    IpcHandler {
        target: "osd"
        function showVolume(arg) { root.volume = arg; osdTimer.restart() }
        function showBrightness(arg) { root.brightness = arg; osdTimer.restart() }
    }

    // Hyprland Config Helpers
    property string hyprConfigPath: Quickshell.env("HOME") + "/.config/hypr/hyprland.conf"
    property var monitorConfigs: []

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "/home/cg/.config/hypr/scripts/list-apps.sh"])
        appsFileView.reload()
    }

    function closeAllPanels() {
        startMenu.visible = false
        actionCenter.visible = false
        widgetsPanel.visible = false
        powerMenu.visible = false
        popupPowerMenu.visible = false
        allAppsPanel.visible = false
        workspaceOverview.visible = false
        powerProfilesPanel.visible = false
        settingsPanel.visible = false
    }

    function getIconPath(iconName) {
        return "image://icon/" + iconName
    }

    property var allApps: []

    FileProxy {
        id: appsFileView
        path: "/tmp/quickshell_apps.txt"
        onContentsChanged: readAllApps()
    }

    function readAllApps() {
        try {
            var content = appsFileView.contents
            var lines = content.split("\n")
            allApps = []
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line && line.includes(",")) {
                    var parts = line.split(",")
                    if (parts.length >= 2) {
                        allApps.push({
                            name: parts[0].trim(),
                            exec: parts[1].trim(),
                            icon: parts.length > 2 ? parts[2].trim() : ""
                        })
                    }
                }
            }
        } catch(e) {}
    }

    // OSD Timer
    Timer {
        id: osdTimer
        interval: 2000
    }

    // OSD Overlay
    Rectangle {
        id: osd
        visible: osdTimer.running
        anchors.centerIn: parent
        width: 120
        height: 80
        color: Qt.rgba(0, 0, 0, 0.8)
        radius: 12
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: osdIcon
                font.family: root.iconFont
                font.pixelSize: 32
                color: root.textColor
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: osdValue + "%"
                font.pixelSize: 14
                color: root.textColor
            }
        }
        property string osdIcon: "🔊"
        property int osdValue: 0
    }

    // Import panels and widgets
    property var startMenuComponent: Qt.include("./panels/StartMenu.qml")
    property var actionCenterComponent: Qt.include("./panels/ActionCenter.qml")
    property var powerMenuComponent: Qt.include("./panels/PowerMenu.qml")
    property var popupPowerMenuComponent: Qt.include("./panels/PopupPowerMenu.qml")
    property var allAppsPanelComponent: Qt.include("./panels/AllAppsPanel.qml")
    property var workspaceOverviewComponent: Qt.include("./panels/WorkspaceOverview.qml")
    property var settingsPanelComponent: Qt.include("./panels/SettingsPanel.qml")
    property var widgetsPanelComponent: Qt.include("./panels/WidgetsPanel.qml")
    property var powerProfilesPanelComponent: Qt.include("./panels/PowerProfilesPanel.qml")
    property var wallpaperSelectorComponent: Qt.include("./panels/WallpaperSelector.qml")
    property var systemTrayComponent: Qt.include("./widgets/SystemTray.qml")

    Loader { id: startMenuLoader; source: "./panels/StartMenu.qml"; active: true }
    Loader { id: actionCenterLoader; source: "./panels/ActionCenter.qml"; active: true }
    Loader { id: powerMenuLoader; source: "./panels/PowerMenu.qml"; active: true }
    Loader { id: popupPowerMenuLoader; source: "./panels/PopupPowerMenu.qml"; active: true }
    Loader { id: allAppsPanelLoader; source: "./panels/AllAppsPanel.qml"; active: true }
    Loader { id: workspaceOverviewLoader; source: "./panels/WorkspaceOverview.qml"; active: true }
    Loader { id: settingsPanelLoader; source: "./panels/SettingsPanel.qml"; active: true }
    Loader { id: widgetsPanelLoader; source: "./panels/WidgetsPanel.qml"; active: true }
    Loader { id: powerProfilesPanelLoader; source: "./panels/PowerProfilesPanel.qml"; active: true }
    Loader { id: wallpaperSelectorLoader; source: "./panels/WallpaperSelector.qml"; active: true }
    Loader { id: systemTrayLoader; source: "./widgets/SystemTray.qml"; active: true }

    // Aliases for loaded components
    property alias startMenu: startMenuLoader.item
    property alias actionCenter: actionCenterLoader.item
    property alias powerMenu: powerMenuLoader.item
    property alias popupPowerMenu: popupPowerMenuLoader.item
    property alias allAppsPanel: allAppsPanelLoader.item
    property alias workspaceOverview: workspaceOverviewLoader.item
    property alias settingsPanel: settingsPanelLoader.item
    property alias widgetsPanel: widgetsPanelLoader.item
    property alias powerProfilesPanel: powerProfilesPanelLoader.item
    property alias wallpaperSelector: wallpaperSelectorLoader.item
    property alias systemTray: systemTrayLoader.item

    // Background click area
    MouseArea {
        anchors.fill: parent; visible: startMenu.visible || actionCenter.visible || widgetsPanel.visible || powerMenu.visible || popupPowerMenu.visible || allAppsPanel.visible || workspaceOverview.visible || powerProfilesPanel.visible || settingsPanel.visible || wallpaperSelector.visible; z: -1
        onClicked: root.closeAllPanels()
    }

    // TB Component with Nerd Font
    component TB: Rectangle {
        property string icon: ""
        property string tip: ""
        property real rot: 0
        property var handler: () => {}
        Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 4
        color: t1.containsMouse ? root.surfaceHover : "transparent"
        Text { anchors.centerIn: parent; text: icon; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor; rotation: rot }
        MouseArea { id: t1; anchors.fill: parent; hoverEnabled: true; onClicked: handler() }
    }
}
