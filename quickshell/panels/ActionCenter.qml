import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: actionCenter
    visible: false; aboveWindows: true; anchors.bottom: true
    implicitWidth: 360; implicitHeight: 420; color: "transparent"
    margins.bottom: 100; margins.left: (Screen.width - 360) / 2; margins.right: (Screen.width - 360) / 2
    
    WlrLayershell.keyboardFocus: visible
    
    onVisibleChanged: {
        if (visible) root.closeAllPanels()
    }
    
    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        radius: 16
        border.color: root.borderColor
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            
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
            
            // Quick toggles grid
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8
                
                // WiFi
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 8
                    color: root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰤨"; font.family: root.iconFont; font.pixelSize: 24; color: root.accentColor }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "WiFi"; font.pixelSize: 11; color: root.textColor }
                    }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                }
                
                // Bluetooth
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 8
                    color: root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: root.bluetoothEnabled ? "󰂯" : "󰂱"; font.family: root.iconFont; font.pixelSize: 24; color: root.bluetoothEnabled ? root.accentColor : root.textSecondary }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Bluetooth"; font.pixelSize: 11; color: root.textColor }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { root.bluetoothEnabled = !root.bluetoothEnabled; Quickshell.execDetached(["blueman-manager"]) } }
                }
                
                // Night Light
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 8
                    color: root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰍔"; font.family: root.iconFont; font.pixelSize: 24; color: root.nightLightEnabled ? root.accentColor : root.textSecondary }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Night Light"; font.pixelSize: 11; color: root.textColor }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { root.nightLightEnabled = !root.nightLightEnabled; Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/nightlight.sh toggle"]) } }
                }
                
                // Airplane Mode
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 8
                    color: root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰓢"; font.family: root.iconFont; font.pixelSize: 24; color: root.textSecondary }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Airplane"; font.pixelSize: 11; color: root.textColor }
                    }
                }
                
                // Dark Mode
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 8
                    color: root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "🌙"; font.pixelSize: 24; color: root.textSecondary }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Dark Mode"; font.pixelSize: 11; color: root.textColor }
                    }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/theme.sh toggle"]) }
                }
                
                // Battery Saver
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 8
                    color: root.surfaceAlt
                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "󱃾"; font.family: root.iconFont; font.pixelSize: 24; color: root.textSecondary }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Battery"; font.pixelSize: 11; color: root.textColor }
                    }
                }
            }
            
            // Separator
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.borderColor }
            
            // Slider controls
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                
                // Brightness slider
                ColumnLayout { Layout.fillWidth: true; spacing: 6
                    RowLayout { Layout.fillWidth: true
                        Text { text: "󰛨"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                        Text { text: "Brightness"; font.pixelSize: 12; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        Text { text: root.brightness + "%"; font.pixelSize: 11; color: root.textSecondary }
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 100; value: root.brightness
                        onMoved: {
                            root.brightness = Math.round(value)
                            Quickshell.execDetached(["bash", "-c", "brightnessctl set " + root.brightness + "%"])
                        }
                        background: Rectangle {
                            width: parent.availableWidth; height: 4; radius: 2
                            color: root.surfaceHover
                            Rectangle { width: parent.width * parent.parent.visualPosition; height: parent.height; radius: 2; color: root.accentColor }
                        }
                        handle: Rectangle { width: 16; height: 16; radius: 8; color: root.textColor }
                    }
                }
                
                // Volume slider
                ColumnLayout { Layout.fillWidth: true; spacing: 6
                    RowLayout { Layout.fillWidth: true
                        Text { text: "󰕾"; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                        Text { text: "Volume"; font.pixelSize: 12; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        Text { text: root.volume + "%"; font.pixelSize: 11; color: root.textSecondary }
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 100; value: root.volume
                        onMoved: {
                            root.volume = Math.round(value)
                            Quickshell.execDetached(["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + root.volume + "%"])
                        }
                        background: Rectangle {
                            width: parent.availableWidth; height: 4; radius: 2
                            color: root.surfaceHover
                            Rectangle { width: parent.width * parent.parent.visualPosition; height: parent.height; radius: 2; color: root.accentColor }
                        }
                        handle: Rectangle { width: 16; height: 16; radius: 8; color: root.textColor }
                    }
                }
            }
            
            // Separator
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.borderColor }
            
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
