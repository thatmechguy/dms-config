import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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
            
            // User profile section
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
                    Layout.fillWidth: true; spacing: 2
                    Text { text: Quickshell.env("USER") || "User"; font.pixelSize: 12; font.weight: Font.DemiBold; color: root.textColor }
                    Text { text: Quickshell.env("HOSTNAME") || "localhost"; font.pixelSize: 10; color: root.textSecondary }
                }
            }
            
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.borderColor }
            
            // Power options grid (2x2)
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 4
                columnSpacing: 4
                
                // Sleep
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                    color: sleepMouse.containsMouse ? root.surfaceHover : root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰤄"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Sleep"; font.pixelSize: 10; color: root.textColor }
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
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰜉"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Restart"; font.pixelSize: 10; color: root.textColor }
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
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰐥"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Power"; font.pixelSize: 10; color: root.textColor }
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
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰀲"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Hibernate"; font.pixelSize: 10; color: root.textColor }
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
                RowLayout { anchors.centerIn: parent; spacing: 10
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
                RowLayout { anchors.centerIn: parent; spacing: 10
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
