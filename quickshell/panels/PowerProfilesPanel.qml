import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: powerProfilesPanel
    visible: false; aboveWindows: true; anchors.bottom: true
    implicitWidth: 280; implicitHeight: 160; color: "transparent"
    margins.bottom: 100; margins.left: (Screen.width - 280) / 2; margins.right: (Screen.width - 280) / 2
    
    Rectangle {
        anchors.fill: parent; color: root.surfaceColor; radius: 12; border.color: root.borderColor; border.width: 1
        
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 8
            
            RowLayout { Layout.fillWidth: true
                Text { text: "⚡"; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                Text { text: "Power Mode"; font.pixelSize: 12; font.weight: Font.DemiBold; color: root.textColor }
                Item { Layout.fillWidth: true }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Repeater {
                    model: ListModel {
                        ListElement { name: "Power Saver"; icon: "󰌪"; profile: "power-saver" }
                        ListElement { name: "Balanced"; icon: "󰗑"; profile: "balanced" }
                        ListElement { name: "Performance"; icon: "󱐋"; profile: "performance" }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 6
                        property bool isActive: root.powerProfile === profile
                        color: ppMouse.containsMouse ? (isActive ? Qt.lighter(root.accentColor, 1.4) : root.surfaceHover) : (isActive ? root.accentColor : root.surfaceAlt)
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Text { text: icon; font.family: root.iconFont; font.pixelSize: 16; color: root.textColor }
                            Text { Layout.fillWidth: true; text: name; font.pixelSize: 12; color: root.textColor }
                            Text { text: isActive ? "󰄬" : ""; font.family: root.iconFont; font.pixelSize: 14; color: root.textColor }
                        }
                        MouseArea { id: ppMouse; anchors.fill: parent; hoverEnabled: true
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
}
