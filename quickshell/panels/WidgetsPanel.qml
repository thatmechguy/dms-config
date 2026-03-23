import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: widgetsPanel
    visible: false; aboveWindows: true; anchors.bottom: true
    implicitWidth: 360; implicitHeight: 300; color: "transparent"
    margins.bottom: 100; margins.left: 20; margins.right: (Screen.width / 2) - 200
    
    WlrLayershell.keyboardFocus: visible
    
    onVisibleChanged: {
        if (visible) root.closeAllPanels()
    }
    
    Rectangle {
        anchors.fill: parent; color: root.surfaceColor; radius: 12; border.color: root.borderColor; border.width: 1
        
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            
            // Header
            RowLayout { Layout.fillWidth: true
                Text { text: "Widgets"; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.textColor }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                    color: closeWidgetsMouse.containsMouse ? root.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 14; color: root.textColor }
                    MouseArea { id: closeWidgetsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: widgetsPanel.visible = false }
                }
            }
            
            // CPU Widget
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 60; color: root.surfaceAlt; radius: 8
                RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Text { text: "🖥️"; font.pixelSize: 24; color: root.textColor }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "CPU"; font.pixelSize: 12; color: root.textColor }
                        Text { text: root.cpuUsage.toFixed(1) + "%"; font.pixelSize: 18; font.weight: Font.DemiBold; color: root.accentColor }
                    }
                }
            }
            
            // Memory Widget
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 60; color: root.surfaceAlt; radius: 8
                RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Text { text: "🧠"; font.pixelSize: 24; color: root.textColor }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Memory"; font.pixelSize: 12; color: root.textColor }
                        Text { text: root.ramUsage.toFixed(1) + "%"; font.pixelSize: 18; font.weight: Font.DemiBold; color: root.accentColor }
                    }
                }
            }
            
            // System Info
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 60; color: root.surfaceAlt; radius: 8
                RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Text { text: "💻"; font.pixelSize: 24; color: root.textColor }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: Quickshell.env("HOSTNAME") || "System"; font.pixelSize: 12; color: root.textColor }
                        Text { text: Quickshell.env("USER") || "User"; font.pixelSize: 10; color: root.textSecondary }
                    }
                }
            }
        }
    }
}
