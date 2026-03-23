import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 900
    height: 650
    minimumWidth: 700
    minimumHeight: 500
    title: "Settings"
    color: "#1e1e1e"
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinMaxButtonsHint

    readonly property color surfaceColor: "#252525"
    readonly property color surfaceContainer: "#2d2d2d"
    readonly property color surfaceContainerHigh: "#383838"
    readonly property color surfaceHover: "#404040"
    readonly property color outline: "#505050"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#999999"
    readonly property color primary: "#0078d4"
    readonly property color primaryContainer: "#004a7c"
    readonly property real cornerRadius: 12
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 16
    readonly property int spacingL: 24
    readonly property int spacingXL: 32
    readonly property int iconSize: 24

    property int brightness: 80
    property int volume: 70
    property real mouseSensitivity: 0.0
    property bool bluetoothEnabled: true
    property bool nightLightEnabled: false
    property bool naturalScroll: false
    property bool darkMode: true
    property string currentWallpaper: ""
    
    ListModel {
        id: themePresets
        ListElement { name: "Nord"; color: "#2E3440"; accent: "#88C0D0" }
        ListElement { name: "Catppuccin"; color: "#1E1E2E"; accent: "#CBA6F7" }
        ListElement { name: "Gruvbox"; color: "#282828"; accent: "#FB4934" }
        ListElement { name: "Dracula"; color: "#282A36"; accent: "#BD93F9" }
        ListElement { name: "Tokyo Night"; color: "#1A1B26"; accent: "#7AA2F7" }
        ListElement { name: "Synthwave"; color: "#1A0A2E"; accent: "#FF79C6" }
        ListElement { name: "Forest"; color: "#2D4A3E"; accent: "#8FBC8F" }
        ListElement { name: "Ocean"; color: "#1A2742"; accent: "#5DADE2" }
    }

    Rectangle {
        anchors.fill: parent
        color: surfaceColor

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                color: surfaceColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: spacingM
                    spacing: spacingS

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: spacingM
                        spacing: spacingM
                        
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: cornerRadius / 2
                            color: primary
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⚙"
                                font.pixelSize: 20
                                color: textPrimary
                            }
                        }
                        
                        Text {
                            text: "Settings"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            color: textPrimary
                        }
                    }

                    // Navigation items
                    ListModel {
                        id: navModel
                        ListElement { icon: "🖥️"; name: "Display & Monitor"; section: "display" }
                        ListElement { icon: "🖱️"; name: "Mouse & Touchpad"; section: "mouse" }
                        ListElement { icon: "⌨️"; name: "Keyboard"; section: "keyboard" }
                        ListElement { icon: "🔊"; name: "Sound"; section: "sound" }
                        ListElement { icon: "🔵"; name: "Bluetooth"; section: "bluetooth" }
                        ListElement { icon: "⚡"; name: "Power"; section: "power" }
                        ListElement { icon: "🎨"; name: "Appearance"; section: "appearance" }
                        ListElement { icon: "🔒"; name: "Privacy & Security"; section: "privacy" }
                        ListElement { icon: "🔄"; name: "System Update"; section: "updates" }
                        ListElement { icon: "ℹ️"; name: "About"; section: "about" }
                    }

                    Repeater {
                        model: navModel
                        delegate: navItem
                    }

                    Item { Layout.fillHeight: true }

                    // Close button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: cornerRadius / 2
                        color: closeMouseArea.containsMouse ? surfaceHover : "transparent"
                        color: "transparent"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: spacingM
                            spacing: spacingM
                            
                            Text { text: "✕"; font.pixelSize: 16; color: textSecondary }
                            Text { Layout.fillWidth: true; text: "Close"; font.pixelSize: 13; color: textSecondary }
                        }
                        
                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.quit()
                        }
                    }
                }
            }

            // Content area
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: parent.width - spacingL * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: spacingM
                    bottomPadding: spacingXL
                    spacing: spacingXL

                    // Display Section
                    SettingsSection {
                        title: "Display & Monitor"
                        icon: "🖥️"
                        visible: contentStack.currentIndex === 0

                        SettingsCard {
                            title: "Brightness"
                            description: "Adjust screen brightness"
                            
                            RowLayout {
                                spacing: spacingM
                                Layout.fillWidth: true
                                
                                Slider {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                    value: brightness
                                    onMoved: brightness = Math.round(value)
                                    
                                    background: Rectangle {
                                        width: parent.availableWidth
                                        height: 8
                                        radius: 4
                                        color: outline
                                        
                                        Rectangle {
                                            width: parent.width * parent.parent.visualPosition
                                            height: parent.height
                                            radius: 4
                                            color: primary
                                        }
                                    }
                                    
                                    handle: Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: textPrimary
                                    }
                                }
                                
                                Text {
                                    text: brightness + "%"
                                    font.pixelSize: 13
                                    color: textSecondary
                                    Layout.preferredWidth: 45
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: cornerRadius / 2
                                color: applyMouse.containsMouse ? primary : primaryContainer
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Apply"
                                    font.pixelSize: 13
                                    color: textPrimary
                                }
                                
                                MouseArea {
                                    id: applyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: execCmd("brightnessctl set " + brightness + "%")
                                }
                            }
                        }

                        SettingsCard {
                            title: "Night Light"
                            description: "Reduce blue light to help you sleep"
                            
                            ToggleSwitch {
                                checked: nightLightEnabled
                                onClicked: {
                                    nightLightEnabled = !nightLightEnabled
                                    execCmd("redshift" + (nightLightEnabled ? " -O 3500" : " -x"))
                                }
                            }
                        }

                        SettingsCard {
                            title: "Resolution"
                            description: "Screen resolution"
                            
                            Text {
                                text: "1920×1080"
                                font.pixelSize: 13
                                color: textSecondary
                            }
                        }

                        SettingsCard {
                            title: "Refresh Rate"
                            description: "Display refresh rate"
                            
                            Text {
                                text: "60 Hz"
                                font.pixelSize: 13
                                color: textSecondary
                            }
                        }
                    }

                    // Mouse Section
                    SettingsSection {
                        title: "Mouse & Touchpad"
                        icon: "🖱️"
                        visible: contentStack.currentIndex === 1

                        SettingsCard {
                            title: "Pointer Speed"
                            description: "Adjust cursor speed"
                            
                            RowLayout {
                                spacing: spacingS
                                Layout.fillWidth: true
                                
                                Text { text: "Slow"; font.pixelSize: 11; color: textSecondary }
                                
                                Slider {
                                    Layout.fillWidth: true
                                    from: -1.0
                                    to: 1.0
                                    stepSize: 0.1
                                    value: mouseSensitivity
                                    onMoved: mouseSensitivity = value
                                    
                                    background: Rectangle {
                                        width: parent.availableWidth
                                        height: 8
                                        radius: 4
                                        color: outline
                                        
                                        Rectangle {
                                            width: parent.width * ((parent.position - from) / (to - from))
                                            height: parent.height
                                            radius: 4
                                            color: primary
                                        }
                                    }
                                    
                                    handle: Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: textPrimary
                                    }
                                }
                                
                                Text { text: "Fast"; font.pixelSize: 11; color: textSecondary }
                            }
                            
                            Text {
                                text: "Current: " + mouseSensitivity.toFixed(1)
                                font.pixelSize: 11
                                color: textSecondary
                                Layout.topMargin: spacingXS
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                Layout.topMargin: spacingS
                                radius: cornerRadius / 2
                                color: applySensMouse.containsMouse ? primary : primaryContainer
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Apply"
                                    font.pixelSize: 13
                                    color: textPrimary
                                }
                                
                                MouseArea {
                                    id: applySensMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        execCmd("sed -i 's/sensitivity =.*/sensitivity = " + mouseSensitivity + "/' ~/.config/hypr/hyprland.conf && hyprctl reload")
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Natural Scrolling"
                            description: "Reverse scroll direction"
                            
                            ToggleSwitch {
                                checked: naturalScroll
                                onClicked: naturalScroll = !naturalScroll
                            }
                        }

                        SettingsCard {
                            title: "Tap to Click"
                            description: "Tap touchpad to click"
                            
                            ToggleSwitch { checked: true }
                        }
                    }

                    // Keyboard Section
                    SettingsSection {
                        title: "Keyboard"
                        icon: "⌨️"
                        visible: contentStack.currentIndex === 2

                        SettingsCard {
                            title: "Keyboard Layout"
                            description: "Current keyboard input source"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "US English"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }

                        SettingsCard {
                            title: "Repeat Keys"
                            description: "Key repeat rate"
                            
                            ToggleSwitch { checked: true }
                        }

                        SettingsCard {
                            title: "Cursor Blinking"
                            description: "Cursor blink rate"
                            
                            ToggleSwitch { checked: true }
                        }
                    }

                    // Sound Section
                    SettingsSection {
                        title: "Sound"
                        icon: "🔊"
                        visible: contentStack.currentIndex === 3

                        SettingsCard {
                            title: "Output Volume"
                            description: "Adjust output volume"
                            
                            RowLayout {
                                spacing: spacingM
                                Layout.fillWidth: true
                                
                                Slider {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                    value: volume
                                    onMoved: volume = Math.round(value)
                                    
                                    background: Rectangle {
                                        width: parent.availableWidth
                                        height: 8
                                        radius: 4
                                        color: outline
                                        
                                        Rectangle {
                                            width: parent.width * parent.visualPosition
                                            height: parent.height
                                            radius: 4
                                            color: primary
                                        }
                                    }
                                    
                                    handle: Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: textPrimary
                                    }
                                }
                                
                                Text {
                                    text: volume + "%"
                                    font.pixelSize: 13
                                    color: textSecondary
                                    Layout.preferredWidth: 45
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                Layout.topMargin: spacingS
                                radius: cornerRadius / 2
                                color: applyVolMouse.containsMouse ? primary : primaryContainer
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Apply"
                                    font.pixelSize: 13
                                    color: textPrimary
                                }
                                
                                MouseArea {
                                    id: applyVolMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: execCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + volume + "%")
                                }
                            }
                        }

                        SettingsCard {
                            title: "Output Device"
                            description: "Where sound is played"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "Built-in Speakers"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }

                        SettingsCard {
                            title: "Input Volume"
                            description: "Microphone input level"
                            
                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: 75
                                
                                background: Rectangle {
                                    width: parent.availableWidth
                                    height: 8
                                    radius: 4
                                    color: outline
                                    
                                    Rectangle {
                                        width: parent.width * parent.visualPosition
                                        height: parent.height
                                        radius: 4
                                        color: primary
                                    }
                                }
                                
                                handle: Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: textPrimary
                                }
                            }
                        }
                    }

                    // Bluetooth Section
                    SettingsSection {
                        title: "Bluetooth"
                        icon: "🔵"
                        visible: contentStack.currentIndex === 4

                        SettingsCard {
                            title: "Bluetooth"
                            description: "Turn Bluetooth on or off"
                            
                            ToggleSwitch {
                                checked: bluetoothEnabled
                                onClicked: {
                                    bluetoothEnabled = !bluetoothEnabled
                                    execCmd("blueman-manager")
                                }
                            }
                        }

                        SettingsCard {
                            title: "Devices"
                            description: "Manage connected devices"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "View devices"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }
                    }

                    // Power Section
                    SettingsSection {
                        title: "Power"
                        icon: "⚡"
                        visible: contentStack.currentIndex === 5

                        SettingsCard {
                            title: "Power Mode"
                            description: "Balance performance and battery"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "Balanced"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }

                        SettingsCard {
                            title: "Screen Blanking"
                            description: "Turn off screen when inactive"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "5 minutes"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }

                        SettingsCard {
                            title: "Suspend"
                            description: "Suspend when inactive"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "15 minutes"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }
                    }

                    // Appearance Section
                    SettingsSection {
                        title: "Appearance"
                        icon: "🎨"
                        visible: contentStack.currentIndex === 6

                        SettingsCard {
                            title: "Dark Mode"
                            description: "Switch between light and dark theme"
                            
                            ToggleSwitch {
                                checked: darkMode
                                onClicked: {
                                    darkMode = !darkMode
                                    execCmd("bash ~/.config/hypr/scripts/theme.sh mode " + (darkMode ? "dark" : "light"))
                                }
                            }
                        }

                        SettingsCard {
                            title: "Wallpaper"
                            description: "Change desktop wallpaper"
                            
                            RowLayout {
                                spacing: spacingM
                                Layout.fillWidth: true
                                
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 68
                                    radius: cornerRadius / 2
                                    color: surfaceContainerHigh
                                    
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        radius: cornerRadius / 2 - 2
                                        source: currentWallpaper !== "" ? "file://" + currentWallpaper : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: currentWallpaper !== ""
                                        asynchronous: true
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "🖼️"
                                        font.pixelSize: 24
                                        color: textSecondary
                                        visible: currentWallpaper === ""
                                    }
                                }
                                
                                ColumnLayout {
                                    spacing: spacingXS
                                    
                                    Text {
                                        text: currentWallpaper !== "" ? currentWallpaper.split('/').pop() : "No wallpaper"
                                        font.pixelSize: 13
                                        color: textPrimary
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 200
                                    }
                                    
                                    Text {
                                        text: darkMode ? "Dark mode" : "Light mode"
                                        font.pixelSize: 11
                                        color: textSecondary
                                    }
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 36
                                    radius: cornerRadius / 2
                                    color: applyWallpaperMouse.containsMouse ? primary : primaryContainer
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Browse..."
                                        font.pixelSize: 12
                                        color: textPrimary
                                    }
                                    
                                    MouseArea {
                                        id: applyWallpaperMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: execCmd("bash ~/.config/hypr/scripts/theme.sh pick")
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Color Presets"
                            description: "Quick theme presets from wallpaper colors"
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 4
                                rowSpacing: spacingS
                                columnSpacing: spacingS
                                
                                Repeater {
                                    model: themePresets
                                    delegate: Rectangle {
                                        property color presetColor: model.color
                                        property color presetAccent: model.accent
                                        
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        radius: cornerRadius / 2
                                        color: surfaceContainerHigh
                                        
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: spacingS
                                            spacing: 2
                                            
                                            RowLayout {
                                                spacing: 4
                                                
                                                Rectangle {
                                                    Layout.preferredWidth: 16
                                                    Layout.preferredHeight: 16
                                                    radius: 4
                                                    color: presetColor
                                                }
                                                
                                                Rectangle {
                                                    Layout.preferredWidth: 16
                                                    Layout.preferredHeight: 16
                                                    radius: 4
                                                    color: presetAccent
                                                }
                                                
                                                Item { Layout.fillWidth: true }
                                            }
                                            
                                            Text {
                                                text: model.name
                                                font.pixelSize: 11
                                                color: textPrimary
                                            }
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: execCmd("bash ~/.config/hypr/scripts/theme.sh preset " + model.name.toLowerCase().replace(" ", "-"))
                                        }
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Animations"
                            description: "Show animations"
                            
                            ToggleSwitch { checked: true }
                        }
                    }

                    // Privacy Section
                    SettingsSection {
                        title: "Privacy & Security"
                        icon: "🔒"
                        visible: contentStack.currentIndex === 7

                        SettingsCard {
                            title: "Lock Screen"
                            description: "When to lock screen"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "5 minutes"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: textSecondary }
                            }
                        }

                        SettingsCard {
                            title: "Auto Lock"
                            description: "Lock after screen turns off"
                            
                            ToggleSwitch { checked: true }
                        }
                    }

                    // Updates Section
                    SettingsSection {
                        title: "System Update"
                        icon: "🔄"
                        visible: contentStack.currentIndex === 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            radius: cornerRadius
                            color: "#22c55e" + "20"
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: spacingS
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "✅"
                                    font.pixelSize: 32
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Your system is up to date"
                                    font.pixelSize: 14
                                    color: "#22c55e"
                                }
                            }
                        }

                        SettingsCard {
                            title: "Check for Updates"
                            description: "Search for new updates"
                            
                            RowLayout {
                                spacing: spacingS
                                
                                Text {
                                    text: "Check now"
                                    font.pixelSize: 13
                                    color: primary
                                }
                                
                                Text { text: "›"; font.pixelSize: 16; color: primary }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: execCmd("kitty -e sudo pacman -Syu")
                            }
                        }
                    }

                    // About Section
                    SettingsSection {
                        title: "About"
                        icon: "ℹ️"
                        visible: contentStack.currentIndex === 9

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            radius: cornerRadius
                            color: surfaceContainer
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: spacingM
                                
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 64
                                    height: 64
                                    radius: cornerRadius
                                    color: primary
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⚙"
                                        font.pixelSize: 32
                                        color: textPrimary
                                    }
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "QuickShell Desktop"
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    color: textPrimary
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Version 1.0.0"
                                    font.pixelSize: 13
                                    color: textSecondary
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Powered by QuickShell & Hyprland"
                                    font.pixelSize: 11
                                    color: textSecondary
                                }
                            }
                        }

                        SettingsCard {
                            title: "Device Name"
                            
                            Text {
                                text: "ArchLinux"
                                font.pixelSize: 13
                                color: textSecondary
                            }
                        }

                        SettingsCard {
                            title: "OS"
                            
                            Text {
                                text: "Arch Linux (64-bit)"
                                font.pixelSize: 13
                                color: textSecondary
                            }
                        }
                    }
                }

                StackLayout {
                    id: contentStack
                    currentIndex: 0
                }
            }
        }
    }

    component navItem: Rectangle {
        required property int index
        required property string icon
        required property string name
        required property string section
        
        property bool isSelected: contentStack.currentIndex === index
        
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: cornerRadius / 2
        color: isSelected ? primary : (mouseArea.containsMouse ? surfaceHover : "transparent")
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: spacingM
            anchors.rightMargin: spacingM
            spacing: spacingM
            
            Text {
                text: icon
                font.pixelSize: 18
                color: textPrimary
            }
            
            Text {
                Layout.fillWidth: true
                text: name
                font.pixelSize: 13
                color: textPrimary
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: contentStack.currentIndex = index
        }
    }

    component SettingsSection: Column {
        property string title: ""
        property string icon: ""
        property bool visible: true
        
        spacing: spacingM
        visible: parent.visible
        
        RowLayout {
            spacing: spacingM
            
            Text { text: icon; font.pixelSize: 28 }
            
            Text {
                text: title
                font.pixelSize: 28
                font.weight: Font.Bold
                color: textPrimary
            }
        }
    }

    component SettingsCard: Rectangle {
        property string title: ""
        property string description: ""
        
        Layout.fillWidth: true
        topPadding: spacingM
        leftPadding: spacingM
        rightPadding: spacingM
        bottomPadding: spacingM
        radius: cornerRadius
        color: surfaceContainer
        
        ColumnLayout {
            anchors.fill: parent
            spacing: spacingS
            
            RowLayout {
                spacing: spacingM
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: title
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: textPrimary
                    }
                    
                    Text {
                        text: description
                        font.pixelSize: 11
                        color: textSecondary
                        visible: description !== ""
                    }
                }
            }
        }
    }

    component ToggleSwitch: Rectangle {
        property bool checked: false
        
        width: 50
        height: 26
        radius: 13
        color: checked ? primary : outline
        
        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: textPrimary
            
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: checked ? undefined : parent
            anchors.right: checked ? parent : undefined
            anchors.leftMargin: checked ? undefined : 3
            anchors.rightMargin: checked ? 3 : undefined
            
            Behavior on anchors.leftMargin { NumberAnimation { duration: 150 } }
            Behavior on anchors.rightMargin { NumberAnimation { duration: 150 } }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: checked = !checked
        }
    }

    function execCmd(cmd) {
        Quickshell.execDetached(["bash", "-c", cmd])
    }
    
    function loadCurrentTheme() {
        Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/theme.sh info"], function(out) {
            var lines = out.split("\n")
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].includes("MODE=")) {
                    darkMode = lines[i].split("=")[1].trim() === "dark"
                }
                if (lines[i].includes("WALLPAPER=")) {
                    currentWallpaper = lines[i].split("=")[1].trim()
                }
            }
        })
    }
    
    Component.onCompleted: {
        loadCurrentTheme()
    }
}
