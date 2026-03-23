import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: systemTray
    visible: true; aboveWindows: true; anchors.top: true; anchors.bottom: false
    implicitWidth: Screen.width; implicitHeight: 32; color: "transparent"
    margins.top: 0; margins.left: 0; margins.right: 0
    margins.bottom: Screen.height - 32
    
    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        border.color: root.borderColor
        border.width: 1
        
        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // Left side - App icons / window controls
            RowLayout {
                Layout.fillHeight: true
                Layout.leftMargin: 8
                spacing: 4
                
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 24; radius: 4
                    color: tray1.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "󰍂"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: tray1; anchors.fill: parent; hoverEnabled: true }
                }
                
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 24; radius: 4
                    color: tray2.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "󰖷"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: tray2; anchors.fill: parent; hoverEnabled: true }
                }
            }
            
            // Center - Spacer (drag area)
            Item { Layout.fillWidth: true; Layout.fillHeight: true }
            
            // Center - Clock
            Rectangle {
                Layout.fillHeight: true
                Layout.leftMargin: 16; Layout.rightMargin: 16
                color: clockMouse.containsMouse ? root.surfaceHover : "transparent"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 8
                    
                    Text {
                        id: clockText
                        text: timeText
                        font.pixelSize: 12
                        color: root.textColor
                    }
                    
                    Text {
                        text: dateText
                        font.pixelSize: 11
                        color: root.textSecondary
                    }
                }
                
                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleActionCenter()
                }
            }
            
            // Center - Spacer (drag area)
            Item { Layout.fillWidth: true; Layout.fillHeight: true }
            
            // Right side - System icons
            RowLayout {
                Layout.fillHeight: true
                Layout.rightMargin: 8
                spacing: 4
                
                // Battery
                Rectangle {
                    Layout.preferredWidth: 52; Layout.preferredHeight: 24; radius: 4
                    color: battMouse.containsMouse ? root.surfaceHover : "transparent"
                    RowLayout { anchors.centerIn: parent; spacing: 4
                        Text { text: root.isCharging ? "󰂄" : "󰁹"; font.family: root.iconFont; font.pixelSize: 12; color: root.textColor }
                        Text { text: root.batteryLevel + "%"; font.pixelSize: 10; color: root.textSecondary }
                    }
                    MouseArea { id: battMouse; anchors.fill: parent; hoverEnabled: true }
                }
                
                // Network
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 24; radius: 4
                    color: netMouse.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "󰤨"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: netMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                }
                
                // Bluetooth
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 24; radius: 4
                    color: btMouse.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: root.bluetoothEnabled ? "󰂯" : "󰂱"; font.family: root.iconFont; font.pixelSize: 14; color: root.bluetoothEnabled ? root.accentColor : root.textSecondary }
                    MouseArea { id: btMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.bluetoothEnabled = !root.bluetoothEnabled; Quickshell.execDetached(["blueman-manager"]) } }
                }
                
                // Volume
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 24; radius: 4
                    color: volMouse.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: root.volumeMuted ? "󰖁" : (root.volume > 50 ? "󰕾" : "󰖀"); font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: volMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["pavucontrol"]) }
                }
                
                // Power Menu
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 24; radius: 4
                    color: powerMouse.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "󰐥"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: popupPowerMenu.toggle() }
                }
            }
        }
    }
    
    // Clock update
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            timeText = Qt.formatTime(now, "HH:mm")
            dateText = Qt.formatDate(now, "ddd d MMM")
        }
    }
    
    property string timeText: "00:00"
    property string dateText: "Mon 1 Jan"
    
    Component.onCompleted: {
        var now = new Date()
        timeText = Qt.formatTime(now, "HH:mm")
        dateText = Qt.formatDate(now, "ddd d MMM")
    }
}
