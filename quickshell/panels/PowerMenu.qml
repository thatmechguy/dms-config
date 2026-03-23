import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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
                            if (a === "suspend") Quickshell.execDetached(["systemctl", "suspend"])
                            else if (a === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
                            else if (a === "shutdown") Quickshell.execDetached(["systemctl", "poweroff"])
                            else Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                        }
                    }
                }
            }
        }
    }
}
