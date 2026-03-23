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

    // Nerd Font family for icons
    property string iconFont: "Symbols Nerd Font"
    property string textFont: "Segoe UI"

    property color accentColor: "#0078d4"
    property color surfaceColor: "#202020"
    property color surfaceAlt: "#2d2d2d"
    property color surfaceHover: "#383838"
    property color borderColor: "#404040"
    property color textColor: "#ffffff"
    property color textSecondary: "#999999"
    property color warningColor: "#ffcc4a"

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
        function toggleWallpaperSelector() { wallpaperSelector.toggle() }
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
    }

    IpcHandler {
        target: "osd"
        function showVolume(arg) { root.volume = arg; osdTimer.restart() }
        function showBrightness(arg) { root.brightness = arg; osdTimer.restart() }
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
    
    // Keyboard shortcuts via IpcHandler
    IpcHandler {
        target: "shell"
        function closePanels() {
            root.closeAllPanels()
            popupPowerMenu.visible = false
        }
    }

    // Hyprland Config Helpers
    property string hyprConfigPath: Quickshell.env("HOME") + "/.config/hypr/hyprland.conf"
    
    // Read value from hyprland.conf
    function readHyprValue(section, key) {
        var result = ""
        var inSection = false
        Quickshell.execDetached(["bash", "-c", "grep -A 50 '\\[" + section + "\\]' " + hyprConfigPath + " | head -50"], function(out) {
            var lines = out.split("\\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith("#") || line === "") continue
                if (line.startsWith("[") && line !== "[" + section + "]") break
                if (line === "[" + section + "]") { inSection = true; continue }
                if (inSection && line.startsWith(key)) {
                    var parts = line.split("=")
                    if (parts.length > 1) result = parts.slice(1).join("=").trim()
                    break
                }
            }
        })
        return result
    }
    
    // Write to hyprland.conf (simple key = value)
    function writeHyprValue(section, key, value) {
        Quickshell.execDetached(["bash", "-c", 
            "sed -i 's/^\\s*" + key + "\\s*=.*/" + key + " = " + value + "/' " + hyprConfigPath + 
            " && hyprctl reload"
        ])
    }
    
    // Get current mouse sensitivity
    function getMouseSensitivity() {
        var sens = 0.0
        Quickshell.execDetached(["bash", "-c", "grep -A 20 '^input {' " + hyprConfigPath + " | grep 'sensitivity' | head -1 | sed 's/.*= *//' | tr -d ' '"], function(out) {
            var val = parseFloat(out.trim())
            if (!isNaN(val)) {
                root.mouseSensitivity = val
            }
        })
        return sens
    }
    
    // Set mouse sensitivity and reload
    function setMouseSensitivity(value) {
        root.mouseSensitivity = value
        Quickshell.execDetached(["bash", "-c", 
            "sed -i '/^input {/,/^}/ { /sensitivity/c\\    sensitivity = " + value + " }' " + hyprConfigPath + 
            " && hyprctl reload"
        ])
    }
    
    // Get current monitor config
    function getMonitorConfig() {
        Quickshell.execDetached(["bash", "-c", "grep '^monitor =' " + hyprConfigPath + " | head -5"], function(out) {
            root.monitorConfigs = []
            var lines = out.trim().split("\\n")
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].replace("monitor = ", "").split(",")
                if (parts.length >= 2) {
                    root.monitorConfigs.push({
                        name: parts[0].trim(),
                        resolution: parts[1].trim()
                    })
                }
            }
        })
    }
    
    // Apply monitor resolution
    function applyMonitorResolution(monitor, resolution) {
        Quickshell.execDetached(["bash", "-c",
            "sed -i 's/monitor = " + monitor + ",.*/monitor = " + monitor + ", " + resolution + ", 0x0, 1/' " + hyprConfigPath +
            " && hyprctl reload"
        ])
    }
    
    // Add new monitor
    function addMonitor(monitor, resolution, position) {
        Quickshell.execDetached(["bash", "-c",
            "echo 'monitor = " + monitor + ", " + resolution + ", " + position + ", 1' >> " + hyprConfigPath +
            " && hyprctl reload"
        ])
    }
    
    // Property to store mouse sensitivity
    property real mouseSensitivity: 0.0
    
    // Property to store monitor configs
    property var monitorConfigs: []
    
    Component.onCompleted: {
        getMouseSensitivity()
        getMonitorConfig()
        Quickshell.execDetached(["bash", "-c", "/home/cg/.config/hypr/scripts/list-apps.sh"])
        appsFileView.reload()
    }

    // Helper to get icon path from icon theme
    function getIconPath(iconName) {
        return "image://icon/" + iconName
    }

    // All apps list property
    property var allApps: []

    FileView {
        id: appsFileView
        path: "/tmp/quickshell-apps.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                var content = text()
                if (content && content !== "") {
                    root.allApps = JSON.parse(content)
                }
            } catch(e) {
                console.log("Error parsing apps JSON:", e)
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { bottom: true; left: true; right: true }
            implicitHeight: 48
            color: "transparent"
            Rectangle {
                anchors.fill: parent
                color: root.surfaceColor
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Qt.lighter(root.borderColor, 1.2) }
            }
            Item {
                anchors.fill: parent
                // LEFT SECTION
                RowLayout {
                    anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    TB { icon: "󰍡"; tip: "Widgets"; handler: () => widgetsPanel.visible = !widgetsPanel.visible }
                    TB { icon: "󰍉"; tip: "Search"; handler: () => { startMenu.visible = true; searchInput.forceActiveFocus() } }
                    TB { icon: "󰕰"; tip: "Task View"; handler: () => { workspaceOverview.visible = !workspaceOverview.visible; if (workspaceOverview.visible) root.closeAllPanels(); } }
                }
                // CENTER SECTION
                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    // Start button
                    Rectangle {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 40; radius: 4
                        color: s1.containsMouse || startMenu.visible ? root.surfaceHover : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "󰖳"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor
                        }
                        MouseArea { id: s1; anchors.fill: parent; hoverEnabled: true; onClicked: { startMenu.visible = !startMenu.visible; if (startMenu.visible) { actionCenter.visible = false; widgetsPanel.visible = false } } }
                    }
                    // Pinned apps with native icons
                    Repeater {
                        model: ListModel {
                            ListElement { n: "Terminal"; ic: "kitty"; c: "kitty"; nf: "󰆍" }
                            ListElement { n: "Browser"; ic: "chromium"; c: "chromium"; nf: "󰖟" }
                            ListElement { n: "Files"; ic: "folder"; c: "nautilus"; nf: "󰉋" }
                        }
                        Rectangle {
                            Layout.preferredWidth: 44; Layout.preferredHeight: 40; radius: 4
                            color: a1.containsMouse ? root.surfaceHover : "transparent"
                            Image {
                                id: img1; anchors.centerIn: parent; width: 24; height: 24
                                source: root.getIconPath(ic)
                                sourceSize.width: 24; sourceSize.height: 24
                                onStatusChanged: { if (status === Image.Error) visible = false }
                            }
                            Text {
                                anchors.centerIn: parent; text: nf; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor
                                visible: img1.status !== Image.Ready
                            }
                            Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 2; anchors.horizontalCenter: parent.horizontalCenter; width: a1.containsMouse ? 8 : 0; height: 3; radius: 1.5; color: root.accentColor; Behavior on width { NumberAnimation { duration: 150 } } }
                            MouseArea { id: a1; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["bash", "-c", c]) }
                        }
                    }
                }
                // RIGHT SECTION
                RowLayout {
                    anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    TB { icon: "󰘁"; rot: 180; tip: "Hidden icons" }
                    // Network
                    Rectangle {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 4
                        color: n1.containsMouse ? root.surfaceHover : "transparent"
                        Text { anchors.centerIn: parent; text: "󰖩"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                        MouseArea { id: n1; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                    }
                    // Volume
                    Rectangle {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 4
                        color: v1.containsMouse ? root.surfaceHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: root.volumeMuted ? "󰖁" : (root.volume < 30 ? "󰕿" : root.volume < 70 ? "󰖀" : "󰕾")
                            font.family: root.iconFont; font.pixelSize: 16; color: root.textColor
                        }
                        MouseArea { id: v1; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["pavucontrol"]); onWheel: w => { if (w.angleDelta.y > 0) Quickshell.execDetached(["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"]); else Quickshell.execDetached(["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"]) } }
                    }
                    // Battery
                    Rectangle {
                        Layout.preferredWidth: 56; Layout.preferredHeight: 36; radius: 4
                        color: b1.containsMouse || powerProfilesPanel.visible ? root.surfaceHover : "transparent"
                        RowLayout { anchors.centerIn: parent; spacing: 4
                            Text {
                                text: {
                                    if (root.isCharging) return "󰂄"
                                    if (root.batteryLevel > 90) return "󰁹"
                                    if (root.batteryLevel > 80) return "󰂂"
                                    if (root.batteryLevel > 70) return "󰂁"
                                    if (root.batteryLevel > 60) return "󰂀"
                                    if (root.batteryLevel > 50) return "󰁿"
                                    if (root.batteryLevel > 40) return "󰁾"
                                    if (root.batteryLevel > 30) return "󰁽"
                                    if (root.batteryLevel > 20) return "󰁼"
                                    if (root.batteryLevel > 10) return "󰁻"
                                    return "󰂎"
                                }
                                font.family: root.iconFont; font.pixelSize: 16; 
                                color: root.batteryLevel <= 15 && !root.isCharging ? root.warningColor : root.textColor
                            }
                            Text { text: root.batteryLevel + "%"; font.pixelSize: 11; color: root.textColor }
                        }
                        MouseArea { 
                            id: b1; anchors.fill: parent; hoverEnabled: true
                            onClicked: { 
                                root.closeAllPanels()
                                powerProfilesPanel.visible = true 
                            }
                        }
                    }
                    // Clock & Notifications (merged)
                    Rectangle {
                        Layout.preferredWidth: 100; Layout.preferredHeight: 36; radius: 4
                        color: c1.containsMouse || actionCenter.visible ? root.surfaceHover : "transparent"
                        RowLayout { anchors.centerIn: parent; spacing: 8
                            ColumnLayout { spacing: 0
                                Text { id: tT; Layout.alignment: Qt.AlignHCenter; text: Qt.formatDateTime(new Date(), "HH:mm"); font.pixelSize: 12; font.weight: Font.Medium; color: root.textColor }
                                Text { id: dT; Layout.alignment: Qt.AlignHCenter; text: Qt.formatDateTime(new Date(), "M/d/yyyy"); font.pixelSize: 10; color: root.textColor }
                            }
                            Text { text: "󰂚"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                        }
                        MouseArea { id: c1; anchors.fill: parent; hoverEnabled: true; onClicked: { actionCenter.visible = !actionCenter.visible; if (actionCenter.visible) { startMenu.visible = false; widgetsPanel.visible = false; powerProfilesPanel.visible = false } } }
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: { tT.text = Qt.formatDateTime(new Date(), "HH:mm"); dT.text = Qt.formatDateTime(new Date(), "M/d/yyyy") } }
                    }
                    // Show Desktop
                    Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 36; color: sd1.containsMouse ? root.surfaceHover : "transparent"; MouseArea { id: sd1; anchors.fill: parent; hoverEnabled: true; onClicked: Hyprland.dispatch("togglespecialworkspace") } }
                }
            }
        }
    }

    // POWER PROFILES PANEL
    PanelWindow {
        id: powerProfilesPanel
        visible: false; aboveWindows: true; anchors.bottom: true; anchors.right: true
        implicitWidth: 200; implicitHeight: 160; color: "transparent"
        margins.bottom: 2; margins.right: 150

        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 8
                // Header
                RowLayout { Layout.fillWidth: true
                    Text { text: "󰖐"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    Text { text: "Power Mode"; font.pixelSize: 12; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                }
                // Power profiles
                Repeater {
                    model: ListModel {
                        ListElement { name: "Power Saver"; icon: "󰌪"; profile: "power-saver" }
                        ListElement { name: "Balanced"; icon: "󰗑"; profile: "balanced" }
                        ListElement { name: "Performance"; icon: "󱐋"; profile: "performance" }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 4
                        property bool isActive: root.powerProfile === profile
                        color: ppMouse.containsMouse ? (isActive ? Qt.lighter(root.accentColor, 1.4) : root.surfaceHover) : (isActive ? root.accentColor : root.surfaceAlt)
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Text { text: icon; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                            Text { Layout.fillWidth: true; text: name; font.pixelSize: 12; color: root.textColor }
                            Text { text: isActive ? "󰄬" : ""; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                        }
                        MouseArea {
                            id: ppMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["powerprofilesctl", "set", profile])
                                root.powerProfile = profile
                                powerProfilesPanel.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    // START MENU
    PanelWindow {
        id: startMenu
        property alias searchField: searchInput
        property string searchText: ""
        visible: false; aboveWindows: true; anchors.bottom: true
        implicitWidth: 600; implicitHeight: 620; color: "transparent"
        margins.bottom: 2; margins.left: (Screen.width - 600) / 2; margins.right: (Screen.width - 600) / 2
        
        WlrLayershell.keyboardFocus: visible
        
        onVisibleChanged: {
            if (visible) {
                searchInput.text = ""
                searchText = ""
                Qt.callLater(function() { searchInput.forceActiveFocus() })
            }
        }
        
        function filterApps(query) {
            searchText = query.toLowerCase()
        }
        
        function getFilteredPinned() {
            if (searchText === "") return pinnedAppsModel
            var filtered = []
            for (var i = 0; i < pinnedAppsModel.count; i++) {
                var item = pinnedAppsModel.get(i)
                if (item.n.toLowerCase().indexOf(searchText) !== -1) {
                    filtered.push({n: item.n, ic: item.ic, c: item.c, nf: item.nf})
                }
            }
            return filtered
        }
        
        function getFilteredAllApps() {
            if (searchText === "") return []
            var filtered = []
            for (var i = 0; i < root.allApps.length; i++) {
                var item = root.allApps[i]
                if (item.name.toLowerCase().indexOf(searchText) !== -1) {
                    filtered.push(item)
                }
            }
            return filtered.slice(0, 12)
        }
        
        ListModel {
            id: pinnedAppsModel
            ListElement { n: "Terminal"; ic: "kitty"; c: "kitty"; nf: "󰍁" }
            ListElement { n: "Browser"; ic: "chromium"; c: "chromium"; nf: "󰖟" }
            ListElement { n: "Files"; ic: "folder"; c: "nautilus"; nf: "󰉋" }
            ListElement { n: "Editor"; ic: "accessories-text-editor"; c: "kitty -e nvim"; nf: "󰎞" }
            ListElement { n: "Monitor"; ic: "btop"; c: "kitty -e btop"; nf: "󰍛" }
            ListElement { n: "Calculator"; ic: "accessories-calculator"; c: "kitty -e python3"; nf: "󰪚" }
            ListElement { n: "Screenshot"; ic: "accessories-screenshot-tool"; c: "hyprshot -m region -o ~/Pictures"; nf: "󰄄" }
            ListElement { n: "Color Picker"; ic: ""; c: "hyprpicker -f hex -a"; nf: "󰈋" }
            ListElement { n: "Clipboard"; ic: ""; c: "cliphist list | rofi -dmenu | cliphist decode | wl-copy"; nf: "󰅌" }
            ListElement { n: "Bluetooth"; ic: "blueman"; c: "blueman-manager"; nf: "󰂯" }
            ListElement { n: "Network"; ic: "network-wired"; c: "nm-connection-editor"; nf: "󰛳" }
            ListElement { n: "Audio"; ic: "audio-card"; c: "pavucontrol"; nf: "󰋃" }
            ListElement { n: "Settings"; ic: "preferences-system"; c: "qmlscene ~/.config/quickshell/settings-app.qml"; nf: "󰒓" }
            ListElement { n: "Night Light"; ic: ""; c: "bash ~/.config/hypr/scripts/nightlight.sh toggle"; nf: "󰓩" }
            ListElement { n: "Lock"; ic: "system-lock-screen"; c: "hyprlock"; nf: "󰌾" }
            ListElement { n: "Video"; ic: "mpv"; c: "mpv"; nf: "󰎃" }
            ListElement { n: "Image"; ic: ""; c: "imv"; nf: "󰋩" }
            ListElement { n: "Wallpaper"; ic: ""; c: "bash ~/.config/hypr/scripts/theme.sh pick"; nf: "󰸉" }
            ListElement { n: "Discord"; ic: "discord"; c: "discord"; nf: "󰙯" }
            ListElement { n: "Spotify"; ic: "spotify"; c: "spotify"; nf: "󰓇" }
            ListElement { n: "Steam"; ic: "steam"; c: "steam"; nf: "󰕓" }
            ListElement { n: "Mail"; ic: "thunderbird"; c: "thunderbird"; nf: "󰇮" }
            ListElement { n: "Music"; ic: "audacious"; c: "audacious"; nf: "�½" }
            ListElement { n: "Notes"; ic: "notes"; c: "obsidian"; nf: "󰌋" }
            ListElement { n: "Camera"; ic: "camera"; c: "gtk4-camera"; nf: "�，拍" }
        }
        
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16
                // Search
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 40; color: root.surfaceAlt; radius: 20
                    border.color: searchInput.activeFocus ? root.accentColor : root.borderColor; border.width: 1
                    RowLayout { anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8
                        Text { text: "󰍉"; font.family: root.iconFont; font.pixelSize: 14; color: root.textSecondary }
                        TextInput { 
                            id: searchInput; Layout.fillWidth: true; font.pixelSize: 14; color: root.textColor; clip: true; focus: true
                            onTextChanged: startMenu.filterApps(text)
                            onActiveFocusChanged: {
                                if (!activeFocus && startMenu.visible) {
                                    forceActiveFocus()
                                }
                            }
                            Text { anchors.fill: parent; text: "Search for apps, settings, and documents"; font.pixelSize: 14; color: root.textSecondary; visible: searchInput.text.length === 0 && !searchInput.activeFocus }
                        }
                    }
                }
                
                // Search results (shown when typing)
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: startMenu.searchText !== ""
                    spacing: 8
                    
                    Text { text: "Search Results"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                    
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        ListView {
                            width: parent.width
                            model: startMenu.getFilteredAllApps()
                            spacing: 2
                            
                            delegate: Rectangle {
                                width: ListView.view.width; height: 44; radius: 4
                                color: searchResultMouse.containsMouse ? root.surfaceAlt : "transparent"
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                                    Rectangle { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 4; color: Qt.lighter(root.surfaceAlt, 1.2)
                                        Image {
                                            id: searchIconImg; anchors.centerIn: parent; width: 24; height: 24
                                            source: modelData.icon ? root.getIconPath(modelData.icon) : ""
                                            sourceSize.width: 24; sourceSize.height: 24
                                            onStatusChanged: { if (status === Image.Error) visible = false }
                                        }
                                        Text {
                                            anchors.centerIn: parent; text: "󰀻"; font.family: root.iconFont; font.pixelSize: 16; color: root.textSecondary
                                            visible: !modelData.icon || searchIconImg.status !== Image.Ready
                                        }
                                    }
                                    Text { Layout.fillWidth: true; text: modelData.name; font.pixelSize: 13; color: root.textColor; elide: Text.ElideRight }
                                }
                                MouseArea {
                                    id: searchResultMouse; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { startMenu.visible = false; Quickshell.execDetached(["bash", "-c", modelData.exec]) }
                                }
                            }
                        }
                    }
                }
                
                // Pinned apps (shown when not searching)
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: startMenu.searchText === ""
                    spacing: 16
                    
                    // Pinned header
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Pinned"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        Rectangle { Layout.preferredWidth: 80; Layout.preferredHeight: 28; radius: 4; color: allAppsMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                            Text { anchors.centerIn: parent; text: "All apps 󰅂"; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                            MouseArea { id: allAppsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { startMenu.visible = false; allAppsPanel.visible = true } }
                        }
                    }
                    // Apps grid with scrolling
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        GridLayout {
                            width: parent.width
                            columns: 6; rowSpacing: 4; columnSpacing: 4
                            Repeater {
                                model: pinnedAppsModel
                                Rectangle {
                                    Layout.preferredWidth: 88; Layout.preferredHeight: 88; radius: 4
                                    color: pm.containsMouse ? root.surfaceAlt : "transparent"
                                    ColumnLayout { anchors.centerIn: parent; spacing: 6
                                        Rectangle { Layout.alignment: Qt.AlignHCenter; width: 40; height: 40; radius: 8; color: Qt.lighter(root.surfaceAlt, 1.2)
                                            Image {
                                                id: appImg; anchors.centerIn: parent; width: 24; height: 24
                                                source: ic !== "" ? root.getIconPath(ic) : ""
                                                sourceSize.width: 24; sourceSize.height: 24
                                                onStatusChanged: { if (status === Image.Error) visible = false }
                                            }
                                            Text {
                                                anchors.centerIn: parent; text: nf; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor
                                                visible: ic === "" || appImg.status !== Image.Ready
                                            }
                                        }
                                        Text { Layout.alignment: Qt.AlignHCenter; text: n; font.pixelSize: 11; color: root.textColor; width: 72; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                    }
                                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: { startMenu.visible = false; Quickshell.execDetached(["bash", "-c", c]) } }
                                }
                            }
                        }
                    }
                    // Recommended header
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Recommended"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        Rectangle { Layout.preferredWidth: 60; Layout.preferredHeight: 28; radius: 4; color: moreMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                            Text { anchors.centerIn: parent; text: "More 󰅂"; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                            MouseArea { id: moreMouse; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                    // Recent files grid
                    GridLayout {
                        Layout.fillWidth: true; columns: 4; rowSpacing: 4; columnSpacing: 4
                        Repeater {
                            model: ListModel {
                                ListElement { n: "hyprland.conf"; p: "~/.config/hypr"; t: "Recently"; ic: "󰈙" }
                                ListElement { n: "shell.qml"; p: "~/.config/quickshell"; t: "Recently"; ic: "󰎞" }
                                ListElement { n: "bashrc"; p: "~"; t: "Yesterday"; ic: "󰚌" }
                                ListElement { n: "Documents"; p: "~"; t: "2 days ago"; ic: "󰉋" }
                                ListElement { n: "Downloads"; p: "~/Downloads"; t: "This week"; ic: "󰇮" }
                                ListElement { n: "Pictures"; p: "~/Pictures"; t: "This week"; ic: "󰋩" }
                                ListElement { n: "Music"; p: "~/Music"; t: "Last month"; ic: "󰓇" }
                                ListElement { n: "Videos"; p: "~/Videos"; t: "Last month"; ic: "󰎃" }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 4
                                color: rm.containsMouse ? root.surfaceAlt : "transparent"
                                ColumnLayout { anchors.centerIn: parent; spacing: 6
                                    Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 36; radius: 6; color: Qt.lighter(root.surfaceAlt, 1.2)
                                        Text { anchors.centerIn: parent; text: ic; font.family: root.iconFont; font.pixelSize: 18; color: root.textSecondary }
                                    }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: n; font.pixelSize: 11; color: root.textColor; width: 72; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: t; font.pixelSize: 9; color: root.textSecondary }
                                }
                                MouseArea { 
                                    id: rm; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { 
                                        startMenu.visible = false
                                        Quickshell.execDetached(["bash", "-c", "kitty -e nvim " + p + "/" + n]) 
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom bar (simplified - no power menu)
                Rectangle {
                    Layout.fillWidth: true; 
                    Layout.preferredHeight: 48; 
                    color: root.surfaceAlt; 
                    radius: 4
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        Layout.margins: 8
                        
                        Rectangle {
                            Layout.preferredWidth: 160; Layout.preferredHeight: 36; radius: 4
                            color: u1.containsMouse ? root.surfaceHover : "transparent"
                            RowLayout { anchors.fill: parent; anchors.margins: 6; spacing: 8
                                Rectangle { Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 12; color: root.accentColor
                                    Text { anchors.centerIn: parent; text: "󰋀"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                }
                                Text { Layout.fillWidth: true; text: Quickshell.env("USER") || "User"; font.pixelSize: 12; color: root.textColor }
                            }
                            MouseArea { id: u1; anchors.fill: parent; hoverEnabled: true }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    // ALL APPS PANEL
    PanelWindow {
        id: allAppsPanel
        visible: false; aboveWindows: true; anchors.bottom: true
        implicitWidth: 600; implicitHeight: 580; color: "transparent"
        margins.bottom: 2; margins.left: (Screen.width - 600) / 2; margins.right: (Screen.width - 600) / 2

        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16
                // Header with back button
                RowLayout { Layout.fillWidth: true
                    Rectangle { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 4; color: backBtnMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        Text { anchors.centerIn: parent; text: "󰅂"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor; rotation: 180 }
                        MouseArea { id: backBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { allAppsPanel.visible = false; startMenu.visible = true } }
                    }
                    Text { text: "All apps"; font.pixelSize: 16; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                }
                // Apps list
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: root.allApps
                    clip: true
                    spacing: 2
                    delegate: Rectangle {
                        width: ListView.view.width; height: 40; radius: 4
                        color: appDelMouse.containsMouse ? root.surfaceAlt : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                            // Icon
                            Rectangle { Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 4; color: "transparent"
                                Image {
                                    id: appDelImg; anchors.centerIn: parent; width: 24; height: 24
                                    source: modelData.icon ? root.getIconPath(modelData.icon) : ""
                                    sourceSize.width: 24; sourceSize.height: 24
                                    onStatusChanged: { if (status === Image.Error) visible = false }
                                }
                                Text {
                                    anchors.centerIn: parent; text: "󰀻"; font.family: root.iconFont; font.pixelSize: 18; color: root.textSecondary
                                    visible: !modelData.icon || appDelImg.status !== Image.Ready
                                }
                            }
                            // Name
                            Text { Layout.fillWidth: true; text: modelData.name; font.pixelSize: 13; color: root.textColor; elide: Text.ElideRight }
                        }
                        MouseArea {
                            id: appDelMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                allAppsPanel.visible = false
                                startMenu.visible = false
                                Quickshell.execDetached(["bash", "-c", modelData.exec])
                            }
                        }
                    }
                    // Section header component
                    section.property: "letter"
                    section.criteria: ViewSection.FullString
                    section.delegate: Rectangle {
                        width: ListView.view.width; height: 28; color: "transparent"
                        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: section; font.pixelSize: 12; font.weight: Font.Bold; color: root.accentColor }
                    }
                }
            }
        }
    }

    // WORKSPACE OVERVIEW PANEL
    PanelWindow {
        id: workspaceOverview
        visible: false; aboveWindows: true; anchors.bottom: true
        implicitWidth: 700; implicitHeight: 400; color: "transparent"
        margins.bottom: 2; margins.left: (Screen.width - 700) / 2; margins.right: (Screen.width - 700) / 2

        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 16
                // Header
                RowLayout { Layout.fillWidth: true
                    Text { text: "󰕰"; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                    Text { text: "Task View"; font.pixelSize: 16; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                    Rectangle { Layout.preferredWidth: 80; Layout.preferredHeight: 28; radius: 4; color: newDesktopBtn.containsMouse ? root.surfaceHover : root.surfaceAlt
                        RowLayout { anchors.centerIn: parent; spacing: 4
                            Text { text: "󰐕"; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                            Text { text: "New desktop"; font.pixelSize: 11; color: root.textColor }
                        }
                        MouseArea { id: newDesktopBtn; anchors.fill: parent; hoverEnabled: true; onClicked: Hyprland.dispatch("workspace empty") }
                    }
                }
                // Workspaces grid
                GridLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; columns: 3; rowSpacing: 12; columnSpacing: 12
                    Repeater {
                        model: Hyprland.workspaces
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                            property bool isCurrent: Hyprland.focusedWorkspace?.id === modelData.id
                            color: wsMouse.containsMouse ? Qt.lighter(root.surfaceAlt, 1.3) : root.surfaceAlt
                            border.color: isCurrent ? root.accentColor : "transparent"
                            border.width: isCurrent ? 2 : 0

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 8
                                // Workspace header
                                RowLayout { Layout.fillWidth: true
                                    Rectangle { Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 12; color: isCurrent ? root.accentColor : root.surfaceHover
                                        Text { anchors.centerIn: parent; text: modelData.id; font.pixelSize: 11; font.weight: Font.Bold; color: root.textColor }
                                    }
                                    Text { text: "Desktop " + modelData.id; font.pixelSize: 12; color: root.textColor; font.weight: isCurrent ? Font.DemiBold : Font.Normal }
                                    Item { Layout.fillWidth: true }
                                }
                                // Windows preview
                                Repeater {
                                    model: modelData.toplevels
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 4; color: root.surfaceHover
                                        RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6
                                            Text { text: "󰖯"; font.family: root.iconFont; font.pixelSize: 12; color: root.textSecondary }
                                            Text { Layout.fillWidth: true; text: modelData.title || "Window"; font.pixelSize: 10; color: root.textColor; elide: Text.ElideRight }
                                        }
                                        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: { workspaceOverview.visible = false; Hyprland.dispatch("focuswindow address:" + modelData.address) } }
                                    }
                                }
                                Item { Layout.fillWidth: true; Layout.fillHeight: true }
                            }

                            MouseArea {
                                id: wsMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: { workspaceOverview.visible = false; Hyprland.dispatch("workspace " + modelData.id) }
                            }
                        }
                    }
                    // Empty workspace placeholders
                    Repeater {
                        model: 5
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 8; color: emptyWsMouse.containsMouse ? Qt.lighter(root.surfaceAlt, 1.2) : root.surfaceAlt; opacity: 0.5
                            ColumnLayout { anchors.centerIn: parent
                                Text { Layout.alignment: Qt.AlignHCenter; text: "󰐕"; font.family: root.iconFont; font.pixelSize: 24; color: root.textSecondary }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Empty"; font.pixelSize: 11; color: root.textSecondary }
                            }
                            MouseArea { id: emptyWsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { workspaceOverview.visible = false; Hyprland.dispatch("workspace " + (Hyprland.workspaces.length + index + 1)) } }
                        }
                    }
                }
            }
        }
    }

    // WIDGETS PANEL
    PanelWindow {
        id: widgetsPanel
        visible: false; aboveWindows: true; anchors.bottom: true; anchors.left: true
        implicitWidth: 360; implicitHeight: 500; color: "transparent"
        margins.bottom: 2; margins.left: 8
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                RowLayout { Layout.fillWidth: true
                    Text { text: "Widgets"; font.pixelSize: 16; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                    Text { text: "󰐕 Add widgets"; font.family: root.iconFont; font.pixelSize: 12; color: root.accentColor }
                }
                // Scrollable content
                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    
                    Column {
                        width: parent.width
                        spacing: 12
                        
                        // Weather
                        Rectangle { width: parent.width; height: 100; color: root.surfaceAlt; radius: 8
                            RowLayout { anchors.fill: parent; anchors.margins: 16
                                ColumnLayout { Layout.fillWidth: true
                                    Text { text: "󰖙"; font.family: root.iconFont; font.pixelSize: 36; color: root.textColor }
                                    Text { text: "Sunny"; font.pixelSize: 12; color: root.textSecondary }
                                }
                                ColumnLayout { Layout.alignment: Qt.AlignRight
                                    Text { text: "72°"; font.pixelSize: 32; font.weight: Font.Light; color: root.textColor }
                                    Text { text: "H: 78° L: 65°"; font.pixelSize: 11; color: root.textSecondary }
                                }
                            }
                        }
                        // Calendar
                        Rectangle { width: parent.width; height: 160; color: root.surfaceAlt; radius: 8
                            ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                                RowLayout { Layout.fillWidth: true
                                    Text { text: Qt.formatDateTime(new Date(), "MMMM yyyy"); font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "Today"; font.pixelSize: 12; color: root.accentColor }
                                }
                                GridLayout { Layout.fillWidth: true; columns: 7; rowSpacing: 2; columnSpacing: 2
                                    Repeater { model: ["S","M","T","W","T","F","S"]; Text { Layout.fillWidth: true; text: modelData; font.pixelSize: 10; color: root.textSecondary; horizontalAlignment: Text.AlignHCenter } }
                                    Repeater { model: 35
                                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 20; radius: 10
                                            color: (index+1)===parseInt(Qt.formatDateTime(new Date(),"dd")) ? root.accentColor : "transparent"
                                            Text { anchors.centerIn: parent; text: index<31 ? (index+1).toString() : ""; font.pixelSize: 10; color: root.textColor }
                                        }
                                    }
                                }
                            }
                        }
                        // System
                        Rectangle { width: parent.width; height: 70; color: root.surfaceAlt; radius: 8
                            ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 4
                                Text { text: "System"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                RowLayout { Layout.fillWidth: true; spacing: 24
                                    ColumnLayout { spacing: 0
                                        RowLayout { spacing: 4
                                            Text { text: "󰻠"; font.family: root.iconFont; font.pixelSize: 10; color: root.textSecondary }
                                            Text { text: "CPU"; font.pixelSize: 10; color: root.textSecondary }
                                        }
                                        Text { text: Math.round(root.cpuUsage)+"%"; font.pixelSize: 14; font.weight: Font.Medium; color: root.cpuUsage>80 ? root.warningColor : root.textColor }
                                    }
                                    ColumnLayout { spacing: 0
                                        RowLayout { spacing: 4
                                            Text { text: "󰍛"; font.family: root.iconFont; font.pixelSize: 10; color: root.textSecondary }
                                            Text { text: "RAM"; font.pixelSize: 10; color: root.textSecondary }
                                        }
                                        Text { text: Math.round(root.ramUsage)+"%"; font.pixelSize: 14; font.weight: Font.Medium; color: root.ramUsage>80 ? root.warningColor : root.textColor }
                                    }
                                    ColumnLayout { spacing: 0
                                        RowLayout { spacing: 4
                                            Text { text: "󰉋"; font.family: root.iconFont; font.pixelSize: 10; color: root.textSecondary }
                                            Text { text: "Disk"; font.pixelSize: 10; color: root.textSecondary }
                                        }
                                        Text { text: "45%"; font.pixelSize: 14; font.weight: Font.Medium; color: root.textColor }
                                    }
                                }
                            }
                        }
                        // Media Player
                        Rectangle { width: parent.width; height: 80; color: root.surfaceAlt; radius: 8
                            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                                Rectangle { Layout.preferredWidth: 56; Layout.preferredHeight: 56; radius: 8; color: Qt.lighter(root.surfaceAlt, 1.3)
                                    Text { anchors.centerIn: parent; text: "󰎆"; font.family: root.iconFont; font.pixelSize: 24; color: root.textColor }
                                }
                                ColumnLayout { Layout.fillWidth: true; spacing: 4
                                    Text { text: "No media playing"; font.pixelSize: 12; font.weight: Font.Medium; color: root.textColor; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: "Open a media player"; font.pixelSize: 10; color: root.textSecondary; elide: Text.ElideRight; Layout.fillWidth: true }
                                    RowLayout { spacing: 16
                                        Text { text: "󰒮"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                        Text { text: "󰐊"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                                        Text { text: "󰒭"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                    }
                                }
                            }
                        }
                        // Notes
                        Rectangle { width: parent.width; height: 150; color: root.surfaceAlt; radius: 8
                            ColumnLayout { anchors.fill: parent; anchors.margins: 12
                                RowLayout { spacing: 6
                                    Text { text: "󰎚"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                    Text { text: "Quick Notes"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                }
                                TextEdit { Layout.fillWidth: true; Layout.fillHeight: true; font.pixelSize: 12; color: root.textColor; wrapMode: TextEdit.Wrap; text: "Click to add notes..." }
                            }
                        }
                    }
                }
            }
        }
    }

    // ACTION CENTER
    PanelWindow {
        id: actionCenter
        visible: false; aboveWindows: true; anchors.bottom: true; anchors.right: true
        implicitWidth: 360; implicitHeight: 480; color: "transparent"
        margins.bottom: 2; margins.right: 8
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 16
                RowLayout { Layout.fillWidth: true
                    Text { text: "Notifications"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                    Text { text: "Clear all"; font.pixelSize: 12; color: root.accentColor }
                }
                // Notification
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                    RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                        Rectangle { Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 20; color: root.accentColor
                            Text { anchors.centerIn: parent; text: "󰟀"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                        }
                        ColumnLayout { Layout.fillWidth: true; spacing: 4
                            RowLayout { Layout.fillWidth: true
                                Text { text: "System"; font.pixelSize: 12; font.weight: Font.DemiBold; color: root.textColor }
                                Item { Layout.fillWidth: true }
                                Text { text: "Now"; font.pixelSize: 10; color: root.textSecondary }
                            }
                            Text { text: "Welcome to Windows 11 shell!"; font.pixelSize: 11; color: root.textSecondary; Layout.fillWidth: true }
                        }
                    }
                }
                // Quick Settings header
                RowLayout { Layout.fillWidth: true
                    Text { text: "Quick Settings"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 4
                        color: settingsIconMouse.containsMouse ? root.surfaceHover : "transparent"
                        Text { anchors.centerIn: parent; text: "󰒓"; font.family: root.iconFont; font.pixelSize: 14; color: root.textSecondary }
                        MouseArea { id: settingsIconMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { settingsPanel.visible = !settingsPanel.visible; if (settingsPanel.visible) actionCenter.visible = false }
                        }
                    }
                }
                // Quick Settings grid
                GridLayout { Layout.fillWidth: true; columns: 4; rowSpacing: 8; columnSpacing: 8
                    Repeater {
                        model: ListModel {
                            ListElement { n: "Wi-Fi"; ic: "󰖩" }
                            ListElement { n: "Bluetooth"; ic: "󰂯" }
                            ListElement { n: "Airplane"; ic: "󰀝" }
                            ListElement { n: "Battery"; ic: "󰁹" }
                            ListElement { n: "Focus"; ic: "󰕐" }
                            ListElement { n: "Night"; ic: "󰓩" }
                            ListElement { n: "Nearby"; ic: "󰗰" }
                            ListElement { n: "Project"; ic: "󰍹" }
                        }
                        Rectangle {
                            property bool active: false
                            Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 8
                            color: qs1.containsMouse ? (active ? Qt.lighter(root.accentColor, 1.4) : root.surfaceHover) : (active ? root.accentColor : root.surfaceAlt)
                            ColumnLayout { anchors.centerIn: parent; spacing: 4
                                Text { Layout.alignment: Qt.AlignHCenter; text: ic; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                                Text { Layout.alignment: Qt.AlignHCenter; text: n; font.pixelSize: 9; color: root.textColor }
                            }
                            MouseArea { id: qs1; anchors.fill: parent; hoverEnabled: true; onClicked: parent.active = !parent.active }
                        }
                    }
                }
                // Brightness
                RowLayout { Layout.fillWidth: true; spacing: 8
                    Text { text: "󰃠"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    Slider { Layout.fillWidth: true; from: 0; to: 100; value: root.brightness
                        background: Rectangle { x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2; width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceAlt
                            Rectangle { width: parent.width * parent.parent.position; height: parent.height; radius: 2; color: root.accentColor }
                        }
                        handle: Rectangle { x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); y: parent.topPadding + parent.availableHeight / 2 - height / 2; width: 14; height: 14; radius: 7; color: root.textColor }
                    }
                }
                // Volume
                RowLayout { Layout.fillWidth: true; spacing: 8
                    Text { text: root.volumeMuted ? "󰖁" : "󰕾"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    Slider { Layout.fillWidth: true; from: 0; to: 100; value: root.volume
                        background: Rectangle { x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2; width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceAlt
                            Rectangle { width: parent.width * parent.parent.position; height: parent.height; radius: 2; color: root.accentColor }
                        }
                        handle: Rectangle { x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); y: parent.topPadding + parent.availableHeight / 2 - height / 2; width: 14; height: 14; radius: 7; color: root.textColor }
                    }
                }
                // Battery
                RowLayout { Layout.fillWidth: true
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 4; color: root.surfaceAlt
                        RowLayout { anchors.centerIn: parent; spacing: 6
                            Text { text: root.isCharging ? "󰂄" : "󰁹"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                            Text { text: root.batteryLevel + "%"; font.pixelSize: 11; color: root.textColor }
                            Text { text: root.isCharging ? "Charging" : "On battery"; font.pixelSize: 11; color: root.textSecondary }
                        }
                    }
                    Rectangle { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 4; color: root.surfaceAlt
                        Text { anchors.centerIn: parent; text: "󰏫"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    }
                }
                
                // Power button
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 48; radius: 8; color: pwrACMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                    RowLayout { anchors.fill: parent; anchors.leftMargin: 16; spacing: 12
                        Text { text: "󰐥"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                        Text { Layout.fillWidth: true; text: "Power"; font.pixelSize: 14; color: root.textColor }
                        Text { text: "󰅂"; font.family: root.iconFont; font.pixelSize: 14; color: root.textSecondary }
                    }
                    MouseArea { id: pwrACMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: { actionCenter.visible = false; popupPowerMenu.toggle() }
                    }
                }
            }
        }
    }

    // SETTINGS PANEL
    PanelWindow {
        id: settingsPanel
        visible: false; aboveWindows: true; anchors.top: true
        implicitWidth: 800; implicitHeight: 550; color: "transparent"
        margins.top: (Screen.height - 550) / 2
        margins.left: (Screen.width - 800) / 2
        margins.right: (Screen.width - 800) / 2

        property string currentSection: "network"

        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1

            RowLayout {
                anchors.fill: parent; spacing: 0

                // Sidebar
                Rectangle {
                    Layout.preferredWidth: 200; Layout.fillHeight: true; color: Qt.darker(root.surfaceColor, 1.1); radius: 8
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 4

                        // Header
                        RowLayout { Layout.fillWidth: true; Layout.bottomMargin: 12
                            Text { text: "󰒓"; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                            Text { text: "Settings"; font.pixelSize: 16; font.weight: Font.DemiBold; color: root.textColor }
                        }

                        // Sidebar items
                        Repeater {
                            model: ListModel {
                                ListElement { icon: "󰖩"; name: "Network"; section: "network" }
                                ListElement { icon: "󰍹"; name: "Display"; section: "display" }
                                ListElement { icon: "󰕾"; name: "Sound"; section: "sound" }
                                ListElement { icon: "󰋀"; name: "Devices"; section: "devices" }
                                ListElement { icon: "󰚥"; name: "Power"; section: "power" }
                                ListElement { icon: "🖨️"; name: "Printing"; section: "printing" }
                                ListElement { icon: "󰏗"; name: "Appearance"; section: "appearance" }
                                ListElement { icon: "󰊿"; name: "Privacy"; section: "privacy" }
                                ListElement { icon: "󰚰"; name: "Updates"; section: "updates" }
                                ListElement { icon: "󰋀"; name: "About"; section: "about" }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 4
                                property bool isActive: settingsPanel.currentSection === section
                                color: sidebarMouse.containsMouse ? (isActive ? Qt.lighter(root.accentColor, 1.4) : root.surfaceHover) : (isActive ? root.accentColor : "transparent")
                                RowLayout { anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                    Text { text: icon; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                    Text { Layout.fillWidth: true; text: name; font.pixelSize: 12; color: root.textColor }
                                }
                                MouseArea { id: sidebarMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPanel.currentSection = section }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Close button
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 4
                            color: closeSettingsBtn.containsMouse ? root.surfaceHover : root.surfaceAlt
                            RowLayout { anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                Text { text: "󰅚"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                Text { Layout.fillWidth: true; text: "Close"; font.pixelSize: 12; color: root.textColor }
                            }
                            MouseArea { id: closeSettingsBtn; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPanel.visible = false }
                        }
                    }
                }

                // Content area
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; color: root.surfaceColor
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 24; spacing: 16

                        // Network Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "network"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Network"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // WiFi
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: "󰖩"; font.family: root.iconFont; font.pixelSize: 28; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Wi-Fi"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "Connected to network"; font.pixelSize: 11; color: root.textSecondary }
                                    }
                                    Rectangle { Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12; color: root.accentColor
                                        Rectangle { width: 18; height: 18; radius: 9; color: root.textColor; anchors.right: parent.right; anchors.rightMargin: 3; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }

                            // Ethernet
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: "󰈀"; font.family: root.iconFont; font.pixelSize: 28; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Ethernet"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "Not connected"; font.pixelSize: 11; color: root.textSecondary }
                                    }
                                    Rectangle { Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12; color: root.surfaceHover
                                        Rectangle { width: 18; height: 18; radius: 9; color: root.textSecondary; anchors.left: parent.left; anchors.leftMargin: 3; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Display Section (Hyprland)
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "display"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Display"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // Resolution Settings
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 120; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "󰍹"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                                        Text { text: "Resolution"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                    }
                                    
                                    // Primary Display Resolution
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "Primary Display:"; font.pixelSize: 11; color: root.textSecondary }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            Layout.preferredWidth: 160; Layout.preferredHeight: 32; radius: 6
                                            color: root.surfaceHover
                                            RowLayout { anchors.fill: parent; anchors.leftMargin: 12
                                                TextField {
                                                    id: resolutionInput
                                                    text: "1920x1080@60"
                                                    font.pixelSize: 12
                                                    color: root.textColor
                                                    background: Rectangle { color: "transparent" }
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Text { text: "󰅂"; font.family: root.iconFont; font.pixelSize: 12; color: root.textSecondary }
                                            }
                                            MouseArea { anchors.fill: parent; onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "hyprctl monitors | head -20"], function(out) {
                                                    resolutionInput.text = "1920x1080@60"
                                                })
                                            }}
                                        }
                                    }
                                    
                                    // Apply Resolution Button
                                    Rectangle {
                                        Layout.preferredWidth: 120; Layout.preferredHeight: 32; radius: 6
                                        color: applyResMouse.containsMouse ? root.accentColor : Qt.lighter(root.accentColor, 1.3)
                                        Text { anchors.centerIn: parent; text: "Apply"; font.pixelSize: 12; color: root.textColor }
                                        MouseArea { id: applyResMouse; anchors.fill: parent; hoverEnabled: true
                                            onClicked: Quickshell.execDetached(["bash", "-c", 
                                                "sed -i 's/monitor = ,.*/monitor = , " + resolutionInput.text + ", 0x0, 1/' ~/.config/hypr/hyprland.conf && hyprctl reload"
                                            ])
                                        }
                                    }
                                }
                            }

                            // Mouse Sensitivity
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 8
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "󰏍"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                                        Text { text: "Mouse Sensitivity"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Item { Layout.fillWidth: true }
                                        Text { id: sensValue; text: root.mouseSensitivity.toFixed(1); font.pixelSize: 12; color: root.textSecondary }
                                    }
                                    RowLayout { Layout.fillWidth: true; spacing: 8
                                        Text { text: "-1.0"; font.pixelSize: 10; color: root.textSecondary }
                                        Slider {
                                            id: mouseSensSlider
                                            Layout.fillWidth: true
                                            from: -1.0; to: 1.0; stepSize: 0.1
                                            value: root.mouseSensitivity
                                            onMoved: {
                                                root.mouseSensitivity = value
                                                sensValue.text = value.toFixed(1)
                                            }
                                            background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceHover
                                                Rectangle { width: parent.width * ((parent.position - from) / (to - from)); height: parent.height; radius: 2; color: root.accentColor }
                                            }
                                            handle: Rectangle { x: parent.leftPadding + (parent.position - from) / (to - from) * (parent.availableWidth - width); width: 16; height: 16; radius: 8; color: root.textColor }
                                        }
                                        Text { text: "+1.0"; font.pixelSize: 10; color: root.textSecondary }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 100; Layout.preferredHeight: 28; radius: 4
                                        color: applySensMouse.containsMouse ? root.accentColor : root.surfaceHover
                                        Text { anchors.centerIn: parent; text: "Apply"; font.pixelSize: 11; color: root.textColor }
                                        MouseArea { id: applySensMouse; anchors.fill: parent; hoverEnabled: true
                                            onClicked: root.setMouseSensitivity(root.mouseSensitivity)
                                        }
                                    }
                                }
                            }

                            // Multiple Displays
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 140; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "󰍹"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                                        Text { text: "Multiple Displays"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                    }
                                    
                                    Text { text: "Detected monitors will appear below"; font.pixelSize: 11; color: root.textSecondary }
                                    
                                    // Monitor list
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        
                                        // Monitor 1
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 4
                                            color: root.surfaceHover
                                            RowLayout { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                                                Text { text: "󰍹"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                                                Text { text: "HDMI-A-1"; font.pixelSize: 11; color: root.textColor }
                                                Text { text: "1920x1080@60"; font.pixelSize: 10; color: root.textSecondary }
                                                Item { Layout.fillWidth: true }
                                                Text { text: "Primary"; font.pixelSize: 10; color: root.accentColor }
                                            }
                                        }
                                        
                                        // Add Monitor Button
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 4
                                            color: addMonitorMouse.containsMouse ? root.surfaceHover : "transparent"
                                            Text { anchors.centerIn: parent; text: "＋ Add Monitor"; font.pixelSize: 11; color: root.textSecondary }
                                            MouseArea { id: addMonitorMouse; anchors.fill: parent; hoverEnabled: true
                                                onClicked: Quickshell.execDetached(["bash", "-c", "hyprctl monitors"])
                                            }
                                        }
                                    }
                                }
                            }

                            // Refresh Rate
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 8
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "󰑒"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                                        Text { text: "Refresh Rate"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                    }
                                    RowLayout { Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            Layout.preferredWidth: 80; Layout.preferredHeight: 32; radius: 6
                                            color: root.surfaceHover
                                            Text { anchors.centerIn: parent; text: "60 Hz"; font.pixelSize: 11; color: root.textColor }
                                        }
                                        Rectangle {
                                            Layout.preferredWidth: 80; Layout.preferredHeight: 32; radius: 6
                                            color: root.accentColor
                                            Text { anchors.centerIn: parent; text: "144 Hz"; font.pixelSize: 11; color: root.textColor }
                                        }
                                        Rectangle {
                                            Layout.preferredWidth: 80; Layout.preferredHeight: 32; radius: 6
                                            color: root.surfaceHover
                                            Text { anchors.centerIn: parent; text: "165 Hz"; font.pixelSize: 11; color: root.textColor }
                                        }
                                    }
                                }
                            }

                            // Night Light
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: "󰓩"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Night Light"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "Reduce blue light"; font.pixelSize: 11; color: root.textSecondary }
                                    }
                                    Rectangle { Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12; color: root.nightLightEnabled ? root.accentColor : root.surfaceHover
                                        Rectangle { width: 18; height: 18; radius: 9; color: root.textColor; anchors.right: root.nightLightEnabled ? parent.right : undefined; anchors.left: root.nightLightEnabled ? undefined : parent.left; anchors.leftMargin: 3; anchors.rightMargin: 3; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Sound Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "sound"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Sound"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // Volume
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 8
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: root.volumeMuted ? "󰖁" : "󰕾"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                                        Text { text: "Output Volume"; font.pixelSize: 12; color: root.textColor }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.volume + "%"; font.pixelSize: 12; color: root.textSecondary }
                                    }
                                    Slider { Layout.fillWidth: true; from: 0; to: 100; value: root.volume
                                        background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceHover; Rectangle { width: parent.width * parent.parent.position; height: parent.height; radius: 2; color: root.accentColor } }
                                        handle: Rectangle { x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); width: 14; height: 14; radius: 7; color: root.textColor }
                                    }
                                }
                            }

                            // Output Device
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: "󰓃"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Output Device"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "Speakers"; font.pixelSize: 11; color: root.textSecondary }
                                    }
                                    Text { text: "󰅂"; font.family: root.iconFont; font.pixelSize: 14; color: root.textSecondary }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Devices Section (Hyprland Input)
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "devices"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Devices"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // Mouse Settings
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 120; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "🖱️"; font.pixelSize: 18; color: root.textColor }
                                        Text { text: "Mouse Settings"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                    }
                                    
                                    // Sensitivity
                                    RowLayout { Layout.fillWidth: true
                                        Text { text: "Sensitivity:"; font.pixelSize: 11; color: root.textSecondary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.mouseSensitivity.toFixed(1); font.pixelSize: 11; color: root.textColor }
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: -1.0; to: 1.0; stepSize: 0.1
                                        value: root.mouseSensitivity
                                        onMoved: {
                                            root.mouseSensitivity = value
                                        }
                                        background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceHover
                                            Rectangle { width: parent.width * ((parent.position - from) / (to - from)); height: parent.height; radius: 2; color: root.accentColor }
                                        }
                                        handle: Rectangle { x: parent.leftPadding + (parent.position - from) / (to - from) * (parent.availableWidth - width); width: 14; height: 14; radius: 7; color: root.textColor }
                                    }
                                    
                                    RowLayout { Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            Layout.preferredWidth: 100; Layout.preferredHeight: 28; radius: 4
                                            color: applyDevSensMouse.containsMouse ? root.accentColor : root.surfaceHover
                                            Text { anchors.centerIn: parent; text: "Apply"; font.pixelSize: 11; color: root.textColor }
                                            MouseArea { id: applyDevSensMouse; anchors.fill: parent; hoverEnabled: true
                                                onClicked: root.setMouseSensitivity(root.mouseSensitivity)
                                            }
                                        }
                                        Rectangle {
                                            Layout.preferredWidth: 100; Layout.preferredHeight: 28; radius: 4
                                            color: resetSensMouse.containsMouse ? root.surfaceHover : "transparent"
                                            Text { anchors.centerIn: parent; text: "Reset"; font.pixelSize: 11; color: root.textSecondary }
                                            MouseArea { id: resetSensMouse; anchors.fill: parent; hoverEnabled: true
                                                onClicked: {
                                                    root.mouseSensitivity = 0.0
                                                    root.setMouseSensitivity(0.0)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Natural Scroll
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    Text { text: "Natural Scroll"; font.pixelSize: 13; color: root.textColor }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12
                                        color: root.naturalScroll ? root.accentColor : root.surfaceHover
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; color: root.textColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: root.naturalScroll ? parent.right : undefined
                                            anchors.left: root.naturalScroll ? undefined : parent.left
                                            anchors.leftMargin: 3; anchors.rightMargin: 3
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: {
                                            root.naturalScroll = !root.naturalScroll
                                            Quickshell.execDetached(["bash", "-c",
                                                "sed -i 's/natural_scroll.*/natural_scroll = " + (root.naturalScroll ? "1" : "0") + "/' ~/.config/hypr/hyprland.conf && hyprctl reload"
                                            ])
                                        }}
                                    }
                                }
                            }

                            // Follow Mouse
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    Text { text: "Follow Mouse (focus)"; font.pixelSize: 13; color: root.textColor }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12
                                        color: root.followMouse ? root.accentColor : root.surfaceHover
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; color: root.textColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: root.followMouse ? parent.right : undefined
                                            anchors.left: root.followMouse ? undefined : parent.left
                                            anchors.leftMargin: 3; anchors.rightMargin: 3
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: {
                                            root.followMouse = !root.followMouse
                                            Quickshell.execDetached(["bash", "-c",
                                                "sed -i 's/follow_mouse.*/follow_mouse = " + (root.followMouse ? "1" : "0") + "/' ~/.config/hypr/hyprland.conf && hyprctl reload"
                                            ])
                                        }}
                                    }
                                }
                            }

                            // Keyboard
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 60; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    Text { text: "⌨️"; font.pixelSize: 18; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                                        Text { text: "Keyboard Layout"; font.pixelSize: 13; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "Click to configure with localectl"; font.pixelSize: 10; color: root.textSecondary }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 80; Layout.preferredHeight: 28; radius: 4
                                        color: kbLayoutMouse.containsMouse ? root.surfaceHover : "transparent"
                                        Text { anchors.centerIn: parent; text: "US"; font.pixelSize: 11; color: root.textColor }
                                        MouseArea { id: kbLayoutMouse; anchors.fill: parent; hoverEnabled: true
                                            onClicked: Quickshell.execDetached(["bash", "-c", "kitty -e localectl list-x11-keymaps"])
                                        }
                                    }
                                }
                            }

                            // Bluetooth
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    Text { text: "Bluetooth"; font.pixelSize: 13; color: root.textColor }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12
                                        color: root.bluetoothEnabled ? root.accentColor : root.surfaceHover
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; color: root.textColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: root.bluetoothEnabled ? parent.right : undefined
                                            anchors.left: root.bluetoothEnabled ? undefined : parent.left
                                            anchors.leftMargin: 3; anchors.rightMargin: 3
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: {
                                            root.bluetoothEnabled = !root.bluetoothEnabled
                                            Quickshell.execDetached(["bash", "-c", "blueman-manager"])
                                        }}
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Power Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "power"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Power"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // Battery
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: root.isCharging ? "󰂄" : "󰁹"; font.family: root.iconFont; font.pixelSize: 24; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Battery"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: root.batteryLevel + "% - " + (root.isCharging ? "Charging" : "Discharging"); font.pixelSize: 11; color: root.textSecondary }
                                    }
                                }
                            }

                            // Power Mode
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 140; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    Text { text: "Power Mode"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                    Repeater {
                                        model: ListModel {
                                            ListElement { icon: "󰌪"; name: "Power Saver"; profile: "power-saver" }
                                            ListElement { icon: "󰗑"; name: "Balanced"; profile: "balanced" }
                                            ListElement { icon: "󱐋"; name: "Performance"; profile: "performance" }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 4
                                            property bool isActive: root.powerProfile === profile
                                            color: powerModeMouse.containsMouse ? (isActive ? Qt.lighter(root.accentColor, 1.4) : root.surfaceHover) : (isActive ? root.accentColor : "transparent")
                                            RowLayout { anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                                Text { text: icon; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                                                Text { Layout.fillWidth: true; text: name; font.pixelSize: 11; color: root.textColor }
                                                Text { text: isActive ? "󰄬" : ""; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                                            }
                                            MouseArea { id: powerModeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", profile]); root.powerProfile = profile } }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Printing Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "printing"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Printing"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 100; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.centerIn: parent; spacing: 8
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "󰐪"; font.family: root.iconFont; font.pixelSize: 32; color: root.textSecondary }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "No printers configured"; font.pixelSize: 12; color: root.textSecondary }
                                    Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 120; Layout.preferredHeight: 32; radius: 4; color: addPrinterBtn.containsMouse ? root.accentColor : root.surfaceHover
                                        Text { anchors.centerIn: parent; text: "Add Printer"; font.pixelSize: 11; color: root.textColor }
                                        MouseArea { id: addPrinterBtn; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["system-config-printer"]) }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Appearance Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "appearance"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Appearance"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // Accent Color
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 8
                                    Text { text: "Accent Color"; font.pixelSize: 12; color: root.textColor }
                                    RowLayout { spacing: 8
                                        Repeater {
                                            model: ["#0078d4", "#0099bc", "#7a7574", "#767676", "#ff8c00", "#e81123", "#00cc6a", "#038387", "#00b7c3", "#8764b8"]
                                            Rectangle {
                                                width: 32; height: 32; radius: 16; color: modelData
                                                border.color: root.accentColor === modelData ? root.textColor : "transparent"
                                                border.width: 2
                                                MouseArea { anchors.fill: parent; onClicked: root.accentColor = modelData }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Privacy Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "privacy"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Privacy & Security"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            // Lock Screen
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: "󰌾"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Lock Screen"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "After 5 minutes of inactivity"; font.pixelSize: 11; color: root.textSecondary }
                                    }
                                    Text { text: "󰅂"; font.family: root.iconFont; font.pixelSize: 14; color: root.textSecondary }
                                }
                            }

                            // Screen Lock
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; color: root.surfaceAlt; radius: 8
                                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text { text: "󰍁"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                                        Text { text: "Auto Lock"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                                        Text { text: "Lock when screen turns off"; font.pixelSize: 11; color: root.textSecondary }
                                    }
                                    Rectangle { Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12; color: root.accentColor
                                        Rectangle { width: 18; height: 18; radius: 9; color: root.textColor; anchors.right: parent.right; anchors.rightMargin: 3; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Updates Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "updates"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "Updates"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 120; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.centerIn: parent; spacing: 12
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "󰚰"; font.family: root.iconFont; font.pixelSize: 36; color: root.successColor }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "System is up to date"; font.pixelSize: 14; color: root.textColor }
                                    Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 140; Layout.preferredHeight: 32; radius: 4; color: checkUpdatesBtn.containsMouse ? root.accentColor : root.surfaceHover
                                        Text { anchors.centerIn: parent; text: "Check for updates"; font.pixelSize: 11; color: root.textColor }
                                        MouseArea { id: checkUpdatesBtn; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["kitty", "-e", "sudo", "pacman", "-Syu"]) }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // About Section
                        ColumnLayout {
                            visible: settingsPanel.currentSection === "about"
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16

                            Text { text: "About"; font.pixelSize: 20; font.weight: Font.DemiBold; color: root.textColor }

                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 200; color: root.surfaceAlt; radius: 8
                                ColumnLayout { anchors.centerIn: parent; spacing: 16
                                    Rectangle { Layout.alignment: Qt.AlignHCenter; width: 64; height: 64; radius: 32; color: root.accentColor
                                        Text { anchors.centerIn: parent; text: "󰖳"; font.family: root.iconFont; font.pixelSize: 32; color: root.textColor }
                                    }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "Hyprland Desktop"; font.pixelSize: 16; font.weight: Font.DemiBold; color: root.textColor }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "Version 1.0"; font.pixelSize: 12; color: root.textSecondary }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "Powered by QuickShell"; font.pixelSize: 10; color: root.textSecondary }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }

    // POWER MENU
    PanelWindow {
        id: powerMenu
        visible: false; aboveWindows: true; anchors.bottom: true
        implicitWidth: 280; implicitHeight: 80; color: "transparent"
        margins.bottom: 100; margins.left: (Screen.width - 280) / 2; margins.right: (Screen.width - 280) / 2
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 8; border.color: root.borderColor; border.width: 1
            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                Repeater {
                    model: ListModel {
                        ListElement { ic: "󰤄"; n: "Sleep"; a: "suspend" }
                        ListElement { ic: "󰜉"; n: "Restart"; a: "reboot" }
                        ListElement { ic: "󰐥"; n: "Shutdown"; a: "shutdown" }
                        ListElement { ic: "󰍃"; n: "Logout"; a: "logout" }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 8
                        color: pw1.containsMouse ? root.surfaceHover : root.surfaceAlt
                        ColumnLayout { anchors.centerIn: parent; spacing: 4
                            Text { Layout.alignment: Qt.AlignHCenter; text: ic; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                            Text { Layout.alignment: Qt.AlignHCenter; text: n; font.pixelSize: 10; color: root.textColor }
                        }
                        MouseArea { id: pw1; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                powerMenu.visible = false
                                if (a === "suspend") root.suspend()
                                else if (a === "reboot") root.reboot()
                                else if (a === "shutdown") root.shutdown()
                                else root.logout()
                            }
                        }
                    }
                }
            }
        }
    }

    // POPUP POWER MENU
    PanelWindow {
        id: popupPowerMenu
        visible: false; aboveWindows: true; anchors.bottom: true
        implicitWidth: 320; implicitHeight: 320; color: "transparent"
        margins.bottom: (Screen.height / 2) - 160; margins.left: (Screen.width - 320) / 2; margins.right: (Screen.width - 320) / 2
        
        function toggle() {
            popupPowerMenu.visible = !popupPowerMenu.visible
            actionCenter.visible = false
            widgetsPanel.visible = false
            startMenu.visible = false
        }
        
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 12; border.color: root.borderColor; border.width: 1
            
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 8
                
                // User profile
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                        color: root.accentColor
                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "U")[0].toUpperCase()
                            font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: Quickshell.env("USER") || "User"; font.pixelSize: 12; font.weight: Font.DemiBold; color: root.textColor }
                        Text { text: Quickshell.env("HOSTNAME") || "localhost"; font.pixelSize: 10; color: root.textSecondary }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.borderColor }
                
                // Power grid (2x2) with fixed height
                GridLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    columns: 4
                    rowSpacing: 4
                    columnSpacing: 4
                    
                    // Sleep
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                        color: sleepMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 6
                            Text { Layout.alignment: Qt.AlignHCenter; text: "󰤄"; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Sleep"; font.pixelSize: 9; color: root.textColor }
                            Item { Layout.fillHeight: true }
                        }
                        MouseArea { id: sleepMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { popupPowerMenu.visible = false; Quickshell.execDetached(["systemctl", "suspend"]) }
                        }
                    }
                    
                    // Restart
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                        color: restartMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 6
                            Text { Layout.alignment: Qt.AlignHCenter; text: "󰜉"; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Restart"; font.pixelSize: 9; color: root.textColor }
                            Item { Layout.fillHeight: true }
                        }
                        MouseArea { id: restartMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { popupPowerMenu.visible = false; Quickshell.execDetached(["systemctl", "reboot"]) }
                        }
                    }
                    
                    // Shutdown
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                        color: powerOffMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 6
                            Text { Layout.alignment: Qt.AlignHCenter; text: "󰐥"; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Power"; font.pixelSize: 9; color: root.textColor }
                            Item { Layout.fillHeight: true }
                        }
                        MouseArea { id: powerOffMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { popupPowerMenu.visible = false; Quickshell.execDetached(["systemctl", "poweroff"]) }
                        }
                    }
                    
                    // Hibernate
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                        color: hibernateMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 6
                            Text { Layout.alignment: Qt.AlignHCenter; text: "󰀲"; font.family: root.iconFont; font.pixelSize: 18; color: root.textColor }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Hibernate"; font.pixelSize: 9; color: root.textColor }
                            Item { Layout.fillHeight: true }
                        }
                        MouseArea { id: hibernateMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { popupPowerMenu.visible = false; Quickshell.execDetached(["systemctl", "hibernate"]) }
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.borderColor }
                
                // Lock
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 6
                    color: lockMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                    RowLayout { anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                        Text { text: "󰌾"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                        Text { Layout.fillWidth: true; text: "Lock Screen"; font.pixelSize: 11; color: root.textColor }
                    }
                    MouseArea { id: lockMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: { popupPowerMenu.visible = false; Quickshell.execDetached(["hyprlock"]) }
                    }
                }
                
                // Log off
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 6
                    color: logoffMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                    RowLayout { anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                        Text { text: "󰍃"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                        Text { Layout.fillWidth: true; text: "Log off"; font.pixelSize: 11; color: root.textColor }
                    }
                    MouseArea { id: logoffMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: { popupPowerMenu.visible = false; Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                    }
                }
            }
        }
    }

    // OSD
    PanelWindow {
        id: osd
        visible: osdTimer.running; aboveWindows: true; anchors.top: true
        implicitWidth: 120; implicitHeight: 120; color: "transparent"
        margins.top: 100
        Timer { id: osdTimer; interval: 1500; running: false }
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 12; border.color: root.borderColor; border.width: 1
            ColumnLayout { anchors.centerIn: parent; spacing: 8
                Text { Layout.alignment: Qt.AlignHCenter; text: root.volumeMuted ? "󰖁" : (root.volume < 30 ? "󰕿" : root.volume < 70 ? "󰖀" : "󰕾"); font.family: root.iconFont; font.pixelSize: 32; color: root.textColor }
                Text { Layout.alignment: Qt.AlignHCenter; text: "Volume"; font.pixelSize: 12; color: root.textSecondary }
                Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 80; Layout.preferredHeight: 6; radius: 3; color: root.surfaceAlt
                    Rectangle { width: parent.width * (root.volume / 100); height: parent.height; radius: 3; color: root.accentColor }
                }
                Text { Layout.alignment: Qt.AlignHCenter; text: Math.round(root.volume) + "%"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
            }
        }
    }

    MouseArea {
        anchors.fill: parent; visible: startMenu.visible || actionCenter.visible || widgetsPanel.visible || powerMenu.visible || popupPowerMenu.visible || allAppsPanel.visible || workspaceOverview.visible || powerProfilesPanel.visible; z: -1
        onClicked: root.closeAllPanels()
    }

    // WALLPAPER SELECTOR
    PanelWindow {
        id: wallpaperSelector
        visible: false; aboveWindows: true; anchors.bottom: true
        implicitWidth: 700; implicitHeight: 500; color: "transparent"
        margins.bottom: (Screen.height / 2) - 250; margins.left: (Screen.width - 700) / 2; margins.right: (Screen.width - 700) / 2
        
        property var wallpapers: []
        property string selectedWallpaper: ""
        
        function toggle() {
            visible = !visible
            if (visible) {
                root.closeAllPanels()
                loadWallpapers()
            }
        }
        
        function loadWallpapers() {
            Quickshell.execDetached(["bash", "-c", 
                "find ~/Pictures/Wallpapers -type f \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \\) 2>/dev/null | sort | head -30"
            ], function(out) {
                var lines = out.trim().split("\\n").filter(l => l !== "")
                wallpapers = lines.map(p => ({ path: p, name: p.split("/").pop() }))
            })
        }
        
        function setWallpaper(path) {
            Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/theme.sh set '" + path + "'"])
            visible = false
        }
        
        Rectangle {
            anchors.fill: parent; color: root.surfaceColor; radius: 16; border.color: root.borderColor; border.width: 1
            
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text { text: "🖼️"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                    Text { text: "Wallpaper"; font.pixelSize: 18; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                        color: closeWpMouse.containsMouse ? root.surfaceHover : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 14; color: root.textColor }
                        MouseArea { id: closeWpMouse; anchors.fill: parent; hoverEnabled: true; onClicked: wallpaperSelector.visible = false }
                    }
                }
                
                // Search/filter
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 8; color: root.surfaceAlt
                    RowLayout { anchors.fill: parent; anchors.leftMargin: 12; spacing: 8
                        Text { text: "🔍"; font.family: root.iconFont; font.pixelSize: 14; color: root.textSecondary }
                        TextInput {
                            id: wallpaperFilter
                            Layout.fillWidth: true; Layout.fillHeight: true
                            text: ""; font.pixelSize: 13; color: root.textColor
                            cursorDelegate: Rectangle { visible: false }
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Filter wallpapers..."
                                font.pixelSize: 13
                                color: root.textSecondary
                                visible: parent.text === ""
                            }
                        }
                    }
                }
                
                // Wallpaper grid
                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    
                    GridView {
                        id: wallpaperGrid
                        width: parent.width
                        cellWidth: 168; cellHeight: 108
                        model: wallpaperSelector.wallpapers
                        
                        delegate: Rectangle {
                            width: 160; height: 100; radius: 8; color: root.surfaceAlt
                            border.color: selected ? root.accentColor : "transparent"
                            border.width: 2
                            
                            property bool selected: wallpaperSelector.selectedWallpaper === modelData.path
                            
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 2
                                radius: 6
                                color: root.surfaceAlt
                                
                                Image {
                                    anchors.fill: parent
                                    source: "file://" + modelData.path
                                    fillMode: Image.Cover
                                    asynchronous: true
                                    clip: true
                                }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: mouseWp.containsMouse ? Qt.rgba(0,0,0,0.3) : "transparent"
                                    radius: 6
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.substring(0, 15)
                                        font.pixelSize: 10; color: "#fff"; visible: mouseWp.containsMouse
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: mouseWp; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    wallpaperSelector.selectedWallpaper = modelData.path
                                    wallpaperSelector.setWallpaper(modelData.path)
                                }
                            }
                        }
                    }
                }
                
                // Footer with folder path
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "📁 ~/Pictures/Wallpapers"; font.pixelSize: 11; color: root.textSecondary }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: 100; Layout.preferredHeight: 32; radius: 6
                        color: openFolderMouse.containsMouse ? root.accentColor : root.surfaceAlt
                        Text { anchors.centerIn: parent; text: "Open Folder"; font.pixelSize: 11; color: root.textColor }
                        MouseArea { id: openFolderMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", "-c", "mkdir -p ~/Pictures/Wallpapers && nautilus ~/Pictures/Wallpapers"]) }
                    }
                }
            }
        }
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
