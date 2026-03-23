import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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
        ListElement { n: "Music"; ic: "audacious"; c: "audacious"; nf: "🎵" }
        ListElement { n: "Notes"; ic: "notes"; c: "obsidian"; nf: "📝" }
    }
    
    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        radius: 8
        border.color: root.borderColor
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            
            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: root.surfaceAlt
                radius: 8
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    
                    Text { text: "🔍"; font.family: root.iconFont; font.pixelSize: 16; color: root.textSecondary }
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Type to search..."
                        placeholderTextColor: root.textSecondary
                        color: root.textColor
                        font.pixelSize: 14
                        background: Rectangle { color: "transparent" }
                        onTextChanged: filterApps(text)
                    }
                }
            }
            
            // Content area (search results or pinned apps)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                
                // Search results
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                
                // Pinned apps section
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: startMenu.searchText === ""
                    spacing: 12
                    
                    // Pinned header
                    RowLayout { Layout.fillWidth: true
                        Text { text: "Pinned"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 60; Layout.preferredHeight: 28; radius: 4; color: allAppsMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                            Text { anchors.centerIn: parent; text: "All 󰅂"; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                            MouseArea { id: allAppsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: allAppsPanel.visible = true }
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
                }
            }
            
            // Recommended section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                RowLayout { Layout.fillWidth: true
                    Text { text: "Recommended"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                    Item { Layout.fillWidth: true }
                    Rectangle { Layout.preferredWidth: 60; Layout.preferredHeight: 28; radius: 4; color: moreMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        Text { anchors.centerIn: parent; text: "More 󰅂"; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                        MouseArea { id: moreMouse; anchors.fill: parent; hoverEnabled: true }
                    }
                }
                
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
