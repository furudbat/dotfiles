import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland // <-- Added native Hyprland integration
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import qs.CustomTheme
import QtQuick.Controls

PanelWindow {
    id: root

    // --- 1. OVERLAY & WAYLAND FIXES ---
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: panelBg.implicitWidth + 40
    implicitHeight: panelBg.implicitHeight + 40
    color: "transparent"

    anchors {
        right: true
        top: true
    }

    // --- CLICK OUTSIDE TO CLOSE (Native Hyprland) ---
    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: {
            if (root.isOpen) {
                root.isOpen = false
            }
        }
    }

    // --- HANDLE ESCAPE SHORTCUT ---
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.isOpen) {
                root.isOpen = false
            }
        }
    }

    // --- 2. ANIMATION LOGIC (FIXED) ---
    property bool isOpen: false
    property int selectedIndex: -1
    property int buttonCount: 5

    onIsOpenChanged: {
        if (isOpen) {
            selectedIndex = -1
            panelBg.forceActiveFocus()
        }
    }

    function activateSelected() {
        var commands = [
            Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -l",
            Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -s",
            Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -e",
            Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -r",
            Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -p"
        ]
        if (selectedIndex >= 0 && selectedIndex < commands.length) {
            Quickshell.execDetached(["bash", "-c", commands[selectedIndex]])
            isOpen = false
        }
    }

    // Keep the window mapped to the screen while the animation is playing
    visible: isOpen || slideAnim.running

    margins {
        right: 2
        top: root.currentMargin * 2 + 32
    }

    // Ternary operator: If open, set to 20. If closed, set to -150.
    property real currentMargin: isOpen ? 0 : -150

    // This automatically animates currentMargin whenever it changes!
    Behavior on currentMargin {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }   // <-- Added for Waybar safety
        function close(): void { root.isOpen = false } // <-- Added for Waybar safety
    }

    Process {
        id: powerProcess
        running: false
    }

    // ==========================================
    // MAIN PANEL BACKGROUND (The Pill Shape)
    // ==========================================
    Item {
        id: panelBg
        implicitWidth: 380
        implicitHeight: buttonLayout.implicitHeight + 40 
        anchors.centerIn: parent

        focus: true

        Keys.onUpPressed: {
            if (root.selectedIndex <= 0)
                root.selectedIndex = root.buttonCount - 1
            else
                root.selectedIndex--
        }
        Keys.onDownPressed: {
            if (root.selectedIndex >= root.buttonCount - 1)
                root.selectedIndex = 0
            else
                root.selectedIndex++
        }
        Keys.onReturnPressed: root.activateSelected()
        Keys.onEnterPressed: root.activateSelected()

        RectangularShadow {
            id: shadow
            anchors.fill: mainBgRect
            radius: mainBgRect.radius
            blur: 15
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.4)
        }

        Rectangle {
            id: mainBgRect
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.primary
            border.width: 2
            radius: 1
            opacity: 0.95 // Only the background is transparent
        }

        // ==========================================
        // BUTTON LAYOUT
        // ==========================================
        RowLayout {
            id: buttonLayout
            anchors.centerIn: parent
            spacing: 20

            component PowerButton: Rectangle {
                id: btn
                //property string iconTxt: ""
                property string iconSource: ""
                property string cmd: ""
                property string tooltipText: "" 
                property bool selected: false
                
                // Add a custom signal to the component
                signal clicked()

                implicitWidth: 50
                implicitHeight: 50
                radius: 4 
                
                color: mouseArea.containsMouse ? Theme.primary : "transparent"
                border.color: Theme.primary
                border.width: 1

                /*
                Text {
                    anchors.centerIn: parent
                    source: btn.iconSrc
                    width: 22
                    height: 22
                    sourceSize.width: 22
                    sourceSize.height: 22
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: (mouseArea.containsMouse || btn.selected) ? Theme.background : Theme.primary
                    }
                }
                */

                // Icon with automatic tint
                ColorOverlay {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: Image {
                        source: btn.iconSource
                        fillMode: Image.PreserveAspectFit
                    }
                    color: mouseArea.containsMouse 
                        ? (Theme ? Theme.background : "#1e1e2e")  // darker tint on hover
                        : (Theme ? Theme.primary : "#89b4fa")     // normal tint
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor 

                    onClicked: {
                        // 1. Emit our custom clicked signal
                        btn.clicked()
                        // 2. Trigger the slide-out animation!
                        root.isOpen = false
                    }
                }

                ToolTip.visible: mouseArea.containsMouse
                ToolTip.text: btn.tooltipText
                ToolTip.delay: 500   // optional (ms)
            }

            PowerButton { 
                iconSource: "icons/lock.png"
                selected: root.selectedIndex === 0
                onClicked: { Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -l"]) } 
                tooltipText: "Lock"
            }
            PowerButton { 
                iconSource: "icons/suspend.png"
                selected: root.selectedIndex === 1
                onClicked: { Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -s"]) } 
                tooltipText: "Suspend"
            }
            PowerButton { 
                iconSource: "icons/logout.png"
                selected: root.selectedIndex === 2
                onClicked: { Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -e"]) } 
                tooltipText: "Logout"
            }
            PowerButton { 
                iconSource: "icons/reboot.png"
                selected: root.selectedIndex === 3
                onClicked: { Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -r"]) } 
                tooltipText: "Reboot"
            }
            PowerButton { 
                iconSource: "icons/power.png"
                selected: root.selectedIndex === 4
                onClicked: { Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-power -p"]) } 
                tooltipText: "Power Off"
            }
        }
    }
}
