pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as Commons

PanelWindow {
  id: root

  required property var targetScreen
  property string mode: "idle"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
  property bool showEdge: true
  property bool showPill: true
  property string glowEffect: "pulse"
  property bool hasActiveWindow: false
  property real winX: 0
  property real winY: 0
  property real winW: 0
  property real winH: 0

  readonly property real localWinX: winX - targetScreen.x
  readonly property real localWinY: winY - targetScreen.y
  readonly property bool windowOnThisScreen: hasActiveWindow
    && localWinX + winW > 0 && localWinX < width
    && localWinY + winH > 0 && localWinY < height

  readonly property bool shown: mode !== "idle" && (showEdge || showPill)
  readonly property bool isListening: mode === "listening"

  // Smooth fade-out before hiding the layer-shell surface
  property real containerOpacity: 0.0
  visible: containerOpacity > 0.01 && (showEdge || showPill)

  onShownChanged: {
    containerOpacity = shown ? 1.0 : 0.0
  }

  Behavior on containerOpacity {
    NumberAnimation {
      duration: Commons.Style.duration(root.shown ? 180 : 120)
      easing.type: Easing.OutCubic
    }
  }

  screen: targetScreen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "omarchy-tinyasr-indicator"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: Region {
    width: 0
    height: 0
  }

  readonly property color baseGlowColor: Commons.Color.accent
  property real phase: 0.0

  NumberAnimation on phase {
    running: root.isListening && root.visible
    from: 0.0
    to: Math.PI * 2.0
    duration: root.glowEffect === "breathe" ? 2400 : 1500
    loops: Animation.Infinite
  }

  readonly property real waveSin: 0.5 + 0.5 * Math.sin(phase)
  readonly property real pulse: 0.35 + 0.60 * waveSin

  readonly property color glowColor: {
    if (root.glowEffect === "prism" && root.isListening) {
      var h = (baseGlowColor.hslHue + 0.09 * Math.sin(phase) + 1.0) % 1.0
      var s = Math.max(0.45, baseGlowColor.hslSaturation)
      var l = Math.min(0.75, Math.max(0.45, baseGlowColor.hslLightness))
      return Qt.hsla(h, s, l, 1.0)
    }
    return baseGlowColor
  }

  readonly property int glowWidth: {
    if (root.glowEffect === "breathe" && root.isListening) {
      return Math.round(18 + 24 * waveSin)
    }
    return 28
  }

  function edgeAlphaFor(offset) {
    if (!root.isListening) return 0.22
    if (root.glowEffect === "wave") {
      var v = 0.5 + 0.5 * Math.sin(phase - offset)
      return (0.18 + 0.78 * v) * 0.45
    }
    if (root.glowEffect === "breathe") {
      return (0.28 + 0.72 * waveSin) * 0.46
    }
    return root.pulse * 0.42
  }

  component EdgeGlow: Rectangle {
    id: edge
    property bool horizontal: false
    property real alphaScale: 0.35

    function shade(a) {
      return Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, a * alphaScale)
    }

    gradient: Gradient {
      orientation: edge.horizontal ? Gradient.Horizontal : Gradient.Vertical
      GradientStop { position: 0.0; color: edge.shade(1.0) }
      GradientStop { position: 0.35; color: edge.shade(0.45) }
      GradientStop { position: 1.0; color: edge.shade(0.0) }
    }
  }

  Item {
    anchors.fill: parent
    opacity: root.containerOpacity

    // Edge glow clipped to the active window's inner border (falls back to screen if none)
    Item {
      id: glowBounds
      visible: root.showEdge && (root.windowOnThisScreen || !root.hasActiveWindow)
      x: root.windowOnThisScreen ? root.localWinX : 0
      y: root.windowOnThisScreen ? root.localWinY : 0
      width: root.windowOnThisScreen ? root.winW : parent.width
      height: root.windowOnThisScreen ? root.winH : parent.height
      clip: true

      EdgeGlow {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: root.glowWidth
        alphaScale: root.edgeAlphaFor(0.0)
      }
      EdgeGlow {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.glowWidth
        horizontal: true
        rotation: 180
        alphaScale: root.edgeAlphaFor(Math.PI * 0.5)
      }
      EdgeGlow {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: root.glowWidth
        rotation: 180
        alphaScale: root.edgeAlphaFor(Math.PI)
      }
      EdgeGlow {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: root.glowWidth
        horizontal: true
        alphaScale: root.edgeAlphaFor(Math.PI * 1.5)
      }
    }

    // Floating bottom-center pill positioned inside the active window (or screen fallback)
    Rectangle {
      id: pill
      visible: root.showPill && (root.windowOnThisScreen || !root.hasActiveWindow)

      readonly property real targetCenterX: root.windowOnThisScreen
        ? (root.localWinX + root.winW / 2)
        : (parent.width / 2)
      readonly property real targetBottomY: root.windowOnThisScreen
        ? (root.localWinY + root.winH)
        : parent.height

      x: Math.max(12, Math.min(parent.width - width - 12, targetCenterX - width / 2))
      y: Math.max(12, Math.min(parent.height - height - 12, targetBottomY - height - Commons.Style.space(18)))

      height: Commons.Style.space(36)
      width: pillRow.implicitWidth + Commons.Style.space(28)
      radius: height / 2

      color: Qt.rgba(
        Commons.Color.popups.background.r,
        Commons.Color.popups.background.g,
        Commons.Color.popups.background.b,
        0.92
      )
      border.width: 1
      border.color: Qt.rgba(
        root.glowColor.r,
        root.glowColor.g,
        root.glowColor.b,
        root.isListening ? 0.75 : 0.45
      )

      scale: root.shown ? 1.0 : 0.96
      Behavior on scale {
        NumberAnimation {
          duration: Commons.Style.duration(180)
          easing.type: Easing.Bezier
          easing.bezierCurve: Commons.Style.easeOut
        }
      }

      Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: Commons.Style.space(10)

        // Animated equalizer bars while listening, pulsing dot while transcribing
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 3
          visible: root.isListening

          Repeater {
            model: [
              { minH: 5, maxH: 15, dur: 420 },
              { minH: 7, maxH: 18, dur: 340 },
              { minH: 6, maxH: 14, dur: 480 },
              { minH: 5, maxH: 16, dur: 380 }
            ]

            delegate: Rectangle {
              required property var modelData
              width: 3
              height: modelData.minH
              radius: 1.5
              anchors.verticalCenter: parent.verticalCenter
              color: root.glowColor

              SequentialAnimation on height {
                running: root.isListening && root.visible
                loops: Animation.Infinite
                NumberAnimation { to: modelData.maxH; duration: modelData.dur; easing.type: Easing.InOutSine }
                NumberAnimation { to: modelData.minH; duration: modelData.dur; easing.type: Easing.InOutSine }
              }
            }
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 8
          height: 8
          radius: 4
          visible: !root.isListening
          color: root.glowColor

          SequentialAnimation on opacity {
            running: !root.isListening && root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.isListening ? strings.t("status.listening") : strings.t("status.transcribing")
          color: Commons.Color.popups.text
          font.family: Commons.Style.font.family
          font.pixelSize: Commons.Style.font.body
          font.weight: Font.Medium
        }
      }
    }
  }
}
