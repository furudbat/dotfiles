import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland // <-- Added native Hyprland integration
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.CustomTheme
import QtQuick.Controls

PanelWindow {
    id: root
    
    // --- 1. OVERLAY & WAYLAND FIXES ---
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore 
    
    implicitWidth: panelBg.width
    implicitHeight: panelBg.height
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
    
    // Keep the window mapped to the screen while the animation is playing
    visible: isOpen || slideAnim.running
    
    margins {
        right: 8
        top: root.currentMargin * 2 + 6
    }

    // Ternary operator: If open, set to 20. If closed, set to -150.
    property real currentMargin: isOpen ? 20 : -150 

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
        implicitWidth: buttonLayout.implicitWidth + 40 
        implicitHeight: 80

        Rectangle {
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
                
                implicitWidth: 50
                implicitHeight: 50
                radius: 4 
                
                color: mouseArea.containsMouse ? Theme.primary : "transparent"
                border.color: Theme.primary
                border.width: 1

                /*
                Text {
                    anchors.centerIn: parent
                    text: btn.iconTxt
                    font.family: "monospace" 
                    font.pixelSize: 20
                    color: mouseArea.containsMouse ? Theme.background : Theme.primary
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
                        powerProcess.command = ["bash", "-c", btn.cmd]
                        powerProcess.running = true
                        root.isOpen = false // Trigger the slide-out animation!
                    }
                }

                ToolTip.visible: mouseArea.containsMouse
                ToolTip.text: btn.tooltipText
                ToolTip.delay: 500   // optional (ms)
            }

            PowerButton { 
                iconSource: "icons/lock.png"
                cmd: "pidof hyprlock || hyprlock"
                tooltipText: "Lock"
            }
            PowerButton { 
                iconSource: "icons/suspend.png"
                cmd: "systemctl suspend"
                tooltipText: "Suspend"
            }
            PowerButton { 
                iconSource: "icons/logout.png"
                cmd: "hyprctl dispatch exit"
                tooltipText: "Logout"
            }
            PowerButton { 
                iconSource: "icons/reboot.png"
                cmd: "systemctl reboot"
                tooltipText: "Reboot"
            }
            PowerButton { 
                iconSource: "icons/power.png"
                cmd: "systemctl poweroff"
                tooltipText: "Power Off"
            }
        }
    }
}