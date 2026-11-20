pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  // "idle" | "listening" | "transcribing"
  property string mode: "idle"

  // Visual indicator: "both" | "edge" | "pill" | "none"
  property string indicatorStyle: "both"
  // Glow animation effect: "pulse" | "wave" | "breathe" | "prism"
  property string glowEffect: "pulse"
  // Model filename in ~/.local/share/tinyasr/models/
  property string modelFile: "en-es-it-pt.tzf"
  // Language code(s): e.g. "pt", "en", "pt,en", "auto"
  property string langCode: "pt"
  // Beam width: 4 (accurate) or 1 (greedy/fast)
  property int beamWidth: 4

  // Active window geometry in global compositor coordinates
  property bool hasActiveWindow: false
  property real winX: 0
  property real winY: 0
  property real winW: 0
  property real winH: 0

  readonly property string helperPath: {
    var u = String(Qt.resolvedUrl("scripts/tinyasr-config"))
    return u.indexOf("file://") === 0 ? u.slice(7) : u
  }

  function normalizeStyle(value) {
    var s = String(value || "").trim()
    if (s === "both" || s === "edge" || s === "pill" || s === "none") return s
    return "both"
  }

  function normalizeEffect(value) {
    var e = String(value || "").trim()
    if (e === "pulse" || e === "wave" || e === "breathe" || e === "prism") return e
    return "pulse"
  }

  function normalizeModel(value) {
    var m = String(value || "").trim()
    if (m === "en-es-it-pt.tzf" || m === "en-ru-uk.tzf" || m === "uz.tzf" || m === "en-fa.tzf" || m === "en-km.tzf") {
      return m
    }
    return "en-es-it-pt.tzf"
  }

  function normalizeBeam(value) {
    var n = parseInt(String(value || "").trim(), 10)
    return n === 1 ? 1 : 4
  }

  function normalizeLang(value) {
    var l = String(value || "").trim()
    return /^[A-Za-z0-9_,-]{1,32}$/.test(l) ? l : "pt"
  }

  Process {
    id: readProc
    command: ["python3", root.helperPath, "read"]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        if (line.length > 1024) return
        try {
          var cfg = JSON.parse(line)
          root.indicatorStyle = root.normalizeStyle(cfg.style)
          root.glowEffect = root.normalizeEffect(cfg.effect)
          root.modelFile = root.normalizeModel(cfg.model)
          root.langCode = root.normalizeLang(cfg.lang)
          root.beamWidth = root.normalizeBeam(cfg.beam)
        } catch (e) {}
      }
    }
  }

  Process {
    id: saveProc
  }

  Process {
    id: activeWinProc
    command: ["python3", root.helperPath, "activewindow"]
    stdout: SplitParser {
      onRead: function(line) {
        if (line.length > 1024) {
          root.hasActiveWindow = false
          return
        }
        try {
          var data = JSON.parse(line)
          if (data && data.ok === true && isFinite(data.w) && isFinite(data.h) && data.w > 0 && data.h > 0) {
            root.winX = Number(data.x)
            root.winY = Number(data.y)
            root.winW = Number(data.w)
            root.winH = Number(data.h)
            root.hasActiveWindow = true
            return
          }
        } catch (e) {}
        root.hasActiveWindow = false
      }
    }
  }

  function refreshActiveWindow() {
    activeWinProc.running = false
    activeWinProc.running = true
  }

  function writeConfig(key, value) {
    saveProc.exec(["python3", root.helperPath, "write", String(key), String(value)])
  }

  function setIndicatorStyle(style) {
    var next = root.normalizeStyle(style)
    if (root.indicatorStyle === next) return
    root.indicatorStyle = next
    writeConfig("style", next)
  }

  function setGlowEffect(effect) {
    var next = root.normalizeEffect(effect)
    if (root.glowEffect === next) return
    root.glowEffect = next
    writeConfig("effect", next)
  }

  function setModelFile(model) {
    var next = root.normalizeModel(model)
    if (root.modelFile === next) return
    root.modelFile = next
    writeConfig("model", next)
  }

  function setLangCode(lang) {
    var next = root.normalizeLang(lang)
    if (root.langCode === next) return
    root.langCode = next
    writeConfig("lang", next)
  }

  function setBeamWidth(beam) {
    var next = root.normalizeBeam(beam)
    if (root.beamWidth === next) return
    root.beamWidth = next
    writeConfig("beam", String(next))
  }

  Timer {
    id: safetyTimer
    interval: 60000
    repeat: false
    onTriggered: root.mode = "idle"
  }

  Timer {
    id: previewTimer
    interval: 2000
    repeat: false
    onTriggered: root.setMode("idle")
  }

  function setMode(nextMode) {
    previewTimer.stop()
    if (nextMode !== "idle" && root.mode === "idle") {
      refreshActiveWindow()
    }
    root.mode = nextMode
    if (nextMode === "idle") {
      safetyTimer.stop()
    } else {
      safetyTimer.restart()
    }
  }

  function preview() {
    if (root.indicatorStyle === "none") return
    refreshActiveWindow()
    root.mode = "listening"
    safetyTimer.stop()
    previewTimer.restart()
  }

  Instantiator {
    model: Quickshell.screens

    delegate: Component {
      IndicatorOverlay {
        required property var modelData
        targetScreen: modelData
        mode: root.mode
        showEdge: root.indicatorStyle === "both" || root.indicatorStyle === "edge"
        showPill: root.indicatorStyle === "both" || root.indicatorStyle === "pill"
        glowEffect: root.glowEffect
        hasActiveWindow: root.hasActiveWindow
        winX: root.winX
        winY: root.winY
        winW: root.winW
        winH: root.winH
      }
    }
  }

  IpcHandler {
    target: "tinyasr-indicator"

    function listening(): void { root.setMode("listening") }
    function transcribing(): void { root.setMode("transcribing") }
    function hide(): void { root.setMode("idle") }
    function setStyle(style: string): void { root.setIndicatorStyle(style) }
    function setGlowEffect(effect: string): void { root.setGlowEffect(effect) }
    function setModel(model: string): void { root.setModelFile(model) }
    function setLang(lang: string): void { root.setLangCode(lang) }
    function setBeam(beam: int): void { root.setBeamWidth(beam) }
    function preview(): void { root.preview() }

    function status(): string {
      return JSON.stringify({
        mode: root.mode,
        style: root.indicatorStyle,
        glowEffect: root.glowEffect,
        model: root.modelFile,
        lang: root.langCode,
        beam: root.beamWidth
      })
    }
  }
}
