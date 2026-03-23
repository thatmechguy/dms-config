import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: settingsPanel
    visible: false; aboveWindows: true; anchors.bottom: true
    implicitWidth: 480; implicitHeight: 600; color: "transparent"
    margins.bottom: 100; margins.left: Screen.width - 500; margins.right: 20
    
    WlrLayershell.keyboardFocus: visible
    WlrLayershell.exclusionMode: WlrExclusionMode.AllowPassThrough
    
    property string currentSection: "display"
    
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
            spacing: 12
            
            // Header
            RowLayout { Layout.fillWidth: true
                Text { text: "Settings"; font.pixelSize: 18; font.weight: Font.DemiBold; color: root.textColor }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                    color: closeSettingsMouse.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: closeSettingsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPanel.visible = false }
                }
            }
            
            // Section tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Repeater {
                    model: [
                        { section: "display", icon: "🖥️", label: "Display" },
                        { section: "mouse", icon: "🖱️", label: "Mouse" },
                        { section: "keyboard", icon: "⌨️", label: "Keyboard" },
                        { section: "sound", icon: "🔊", label: "Sound" }
                    ]
                    
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 6
                        color: currentSection === modelData.section ? root.accentColor : (sectionMouse.containsMouse ? root.surfaceHover : root.surfaceAlt)
                        Text { anchors.centerIn: parent; text: modelData.icon + " " + modelData.label; font.pixelSize: 11; color: root.textColor }
                        property string section: modelData.section
                        MouseArea { id: sectionMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPanel.currentSection = modelData.section }
                    }
                }
            }
            
            // Content based on section
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 12
                    
                    // Display Section
                    ColumnLayout {
                        visible: settingsPanel.currentSection === "display"
                        spacing: 12
                        
                        // Brightness
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                            ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                                RowLayout { Layout.fillWidth: true
                                    Text { text: "🔆"; font.pixelSize: 16; color: root.textColor }
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
                                    background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceHover
                                        Rectangle { width: parent.width * parent.parent.visualPosition; height: parent.height; radius: 2; color: root.accentColor } }
                                    handle: Rectangle { width: 16; height: 16; radius: 8; color: root.textColor }
                                }
                            }
                        }
                        
                        // Night Light
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; color: root.surfaceAlt; radius: 8
                            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                                Text { text: "🌙"; font.pixelSize: 20; color: root.textColor }
                                Text { Layout.fillWidth: true; text: "Night Light"; font.pixelSize: 13; color: root.textColor }
                                ToggleSwitch { checked: root.nightLightEnabled
                                    onClicked: { root.nightLightEnabled = !root.nightLightEnabled; Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/nightlight.sh toggle"]) } }
                            }
                        }
                    }
                    
                    // Mouse Section
                    ColumnLayout {
                        visible: settingsPanel.currentSection === "mouse"
                        spacing: 12
                        
                        // Sensitivity
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                            ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                                RowLayout { Layout.fillWidth: true
                                    Text { text: "Sensitivity"; font.pixelSize: 12; color: root.textColor }
                                    Item { Layout.fillWidth: true }
                                    Text { text: root.mouseSensitivity.toFixed(1); font.pixelSize: 11; color: root.textSecondary }
                                }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -1.0; to: 1.0; stepSize: 0.1; value: root.mouseSensitivity
                                    onMoved: root.mouseSensitivity = value
                                    background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceHover
                                        Rectangle { width: parent.width * ((parent.position - from) / (to - from)); height: parent.height; radius: 2; color: root.accentColor } }
                                    handle: Rectangle { width: 16; height: 16; radius: 8; color: root.textColor }
                                }
                                RowLayout {
                                    Text { text: "Slow"; font.pixelSize: 10; color: root.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "Fast"; font.pixelSize: 10; color: root.textSecondary }
                                }
                            }
                        }
                        
                        // Natural Scroll
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; color: root.surfaceAlt; radius: 8
                            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                                Text { Layout.fillWidth: true; text: "Natural Scrolling"; font.pixelSize: 13; color: root.textColor }
                                ToggleSwitch { checked: root.naturalScroll; onClicked: root.naturalScroll = !root.naturalScroll }
                            }
                        }
                    }
                    
                    // Keyboard Section
                    ColumnLayout {
                        visible: settingsPanel.currentSection === "keyboard"
                        spacing: 12
                        
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; color: root.surfaceAlt; radius: 8
                            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                                Text { text: "⌨️"; font.pixelSize: 20; color: root.textColor }
                                Text { Layout.fillWidth: true; text: "Keyboard Layout"; font.pixelSize: 13; color: root.textColor }
                                Text { text: "US"; font.pixelSize: 12; color: root.textSecondary }
                            }
                        }
                    }
                    
                    // Sound Section
                    ColumnLayout {
                        visible: settingsPanel.currentSection === "sound"
                        spacing: 12
                        
                        // Volume
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; color: root.surfaceAlt; radius: 8
                            ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                                RowLayout { Layout.fillWidth: true
                                    Text { text: "🔊"; font.pixelSize: 16; color: root.textColor }
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
                                    background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: root.surfaceHover
                                        Rectangle { width: parent.width * parent.visualPosition; height: parent.height; radius: 2; color: root.accentColor } }
                                    handle: Rectangle { width: 16; height: 16; radius: 8; color: root.textColor }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    component ToggleSwitch: Rectangle {
        property bool checked: false
        width: 44; height: 24; radius: 12; color: checked ? root.accentColor : root.surfaceHover
        Rectangle {
            width: 18; height: 18; radius: 9; color: root.textColor
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: checked ? parent.right : undefined; anchors.left: checked ? undefined : parent.left
            anchors.leftMargin: 3; anchors.rightMargin: 3
        }
        MouseArea { anchors.fill: parent; onClicked: checked = !checked }
    }
}
