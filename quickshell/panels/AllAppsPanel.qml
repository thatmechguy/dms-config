import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: allAppsPanel
    visible: false; aboveWindows: true; anchors.bottom: true
    implicitWidth: 600; implicitHeight: 580; color: "transparent"
    margins.bottom: 2; margins.left: (Screen.width - 600) / 2; margins.right: (Screen.width - 600) / 2
    
    WlrLayershell.keyboardFocus: visible
    
    onVisibleChanged: {
        if (visible) {
            startMenu.visible = false
            Qt.callLater(function() { allAppsSearch.forceActiveFocus() })
        }
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
                        id: allAppsSearch
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Search apps..."
                        placeholderTextColor: root.textSecondary
                        color: root.textColor
                        font.pixelSize: 14
                        background: Rectangle { color: "transparent" }
                        onTextChanged: filterApps(text)
                    }
                }
            }
            
            // Apps grid
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                GridLayout {
                    id: allAppsGrid
                    width: parent.width
                    columns: 6
                    rowSpacing: 4
                    columnSpacing: 4
                    
                    Repeater {
                        model: ListModel { id: allAppsFiltered }
                        
                        Rectangle {
                            Layout.preferredWidth: 88; Layout.preferredHeight: 88; radius: 4
                            color: allAppItem.containsMouse ? root.surfaceAlt : "transparent"
                            ColumnLayout { anchors.centerIn: parent; spacing: 6
                                Rectangle { Layout.alignment: Qt.AlignHCenter; width: 40; height: 40; radius: 8; color: Qt.lighter(root.surfaceAlt, 1.2)
                                    Image {
                                        id: allAppImg; anchors.centerIn: parent; width: 24; height: 24
                                        source: model.icon ? root.getIconPath(model.icon) : ""
                                        sourceSize.width: 24; sourceSize.height: 24
                                        onStatusChanged: { if (status === Image.Error) visible = false }
                                    }
                                    Text {
                                        anchors.centerIn: parent; text: "󰀻"; font.family: root.iconFont; font.pixelSize: 20; color: root.textColor
                                        visible: !model.icon || allAppImg.status !== Image.Ready
                                    }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; text: model.name; font.pixelSize: 11; color: root.textColor; width: 72; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                            }
                            MouseArea { id: allAppItem; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    allAppsPanel.visible = false
                                    Quickshell.execDetached(["bash", "-c", model.exec])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    function filterApps(query) {
        allAppsFiltered.clear()
        var q = query.toLowerCase()
        for (var i = 0; i < root.allApps.length; i++) {
            var app = root.allApps[i]
            if (q === "" || app.name.toLowerCase().indexOf(q) !== -1) {
                allAppsFiltered.append(app)
            }
        }
    }
    
    Component.onCompleted: {
        filterApps("")
    }
}
