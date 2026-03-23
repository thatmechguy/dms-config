import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: workspaceOverview
    visible: false; aboveWindows: true; anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.5)
    
    MouseArea { anchors.fill: parent; onClicked: workspaceOverview.visible = false }
    
    Rectangle {
        anchors.centerIn: parent
        width: 800
        height: 500
        color: root.surfaceColor
        radius: 16
        border.color: root.borderColor
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Workspace Overview"
                font.pixelSize: 24
                font.weight: Font.DemiBold
                color: root.textColor
            }
            
            // Workspace tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Repeater {
                    model: ListModel {
                        ListElement { ws: "1"; name: "Workspace 1" }
                        ListElement { ws: "2"; name: "Workspace 2" }
                        ListElement { ws: "3"; name: "Workspace 3" }
                        ListElement { ws: "4"; name: "Workspace 4" }
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 100; Layout.preferredHeight: 36; radius: 6
                        color: wsMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                        Text { anchors.centerIn: parent; text: name; font.pixelSize: 12; color: root.textColor }
                        MouseArea { id: wsMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", ws])
                                workspaceOverview.visible = false
                            }
                        }
                    }
                }
            }
            
            // Windows preview area
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: root.surfaceAlt
                radius: 8
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text { text: "🪟"; font.pixelSize: 48; color: root.textSecondary }
                    Text { text: "Active windows will appear here"; font.pixelSize: 14; color: root.textSecondary }
                }
            }
            
            // Bottom bar
            RowLayout {
                Layout.fillWidth: true
                
                Rectangle {
                    Layout.preferredWidth: 100; Layout.preferredHeight: 36; radius: 6
                    color: closeOverviewMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                    Text { anchors.centerIn: parent; text: "Close"; font.pixelSize: 12; color: root.textColor }
                    MouseArea { id: closeOverviewMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: workspaceOverview.visible = false }
                }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    Layout.preferredWidth: 100; Layout.preferredHeight: 36; radius: 6
                    color: newWsMouse.containsMouse ? root.accentColor : root.surfaceAlt
                    Text { anchors.centerIn: parent; text: "New WS"; font.pixelSize: 12; color: root.textColor }
                    MouseArea { id: newWsMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "empty"]) }
                }
            }
        }
    }
}
