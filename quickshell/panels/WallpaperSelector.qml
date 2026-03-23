import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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
                        
                        MouseArea { id: mouseWp; anchors.fill: parent; hoverEnabled: true
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
