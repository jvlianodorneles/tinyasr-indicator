pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root

  moduleName: "dorneles.tinyasr-indicator"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property var indicatorService: {
    if (!bar || !bar.shell || typeof bar.shell.serviceFor !== "function") return null
    return bar.shell.serviceFor(root.moduleName)
  }

  readonly property string currentStyle: indicatorService ? indicatorService.indicatorStyle : "both"
  readonly property string currentEffect: indicatorService ? indicatorService.glowEffect : "pulse"
  readonly property string currentModel: indicatorService ? indicatorService.modelFile : "en-es-it-pt.tzf"
  readonly property string currentLang: indicatorService ? indicatorService.langCode : "pt"
  readonly property int currentBeam: indicatorService ? indicatorService.beamWidth : 4
  readonly property bool isActive: indicatorService ? indicatorService.mode !== "idle" : false

  property bool opened: false

  readonly property var modelCatalog: [
    {
      file: "en-es-it-pt.tzf",
      label: "EN · ES · IT · PT",
      langs: [
        { code: "pt", label: "PT" },
        { code: "en", label: "EN" },
        { code: "es", label: "ES" },
        { code: "it", label: "IT" },
        { code: "pt,en", label: "PT+EN" },
        { code: "auto", label: "Auto" }
      ]
    },
    {
      file: "en-ru-uk.tzf",
      label: "EN · RU · UK",
      langs: [
        { code: "en", label: "EN" },
        { code: "ru", label: "RU" },
        { code: "uk", label: "UK" },
        { code: "auto", label: "Auto" }
      ]
    },
    {
      file: "uz.tzf",
      label: "Uzbek (Latn / Cyrl)",
      langs: [
        { code: "uz-Latn", label: "Latn" },
        { code: "uz-Cyrl", label: "Cyrl" },
        { code: "uz-Latin-Russian", label: "Mix" },
        { code: "auto", label: "Auto" }
      ]
    },
    {
      file: "en-fa.tzf",
      label: "EN · FA",
      langs: [
        { code: "en", label: "EN" },
        { code: "fa", label: "FA" },
        { code: "auto", label: "Auto" }
      ]
    },
    {
      file: "en-km.tzf",
      label: "EN · KM",
      langs: [
        { code: "en", label: "EN" },
        { code: "km", label: "KM" },
        { code: "auto", label: "Auto" }
      ]
    }
  ]

  readonly property var activeModelEntry: {
    for (var i = 0; i < modelCatalog.length; i++) {
      if (modelCatalog[i].file === currentModel) return modelCatalog[i]
    }
    return modelCatalog[0]
  }

  readonly property var styleOptions: [
    { value: "both", labelKey: "style.both" },
    { value: "edge", labelKey: "style.edge" },
    { value: "pill", labelKey: "style.pill" },
    { value: "none", labelKey: "style.none" }
  ]

  readonly property var effectOptions: [
    { value: "pulse", labelKey: "effect.pulse" },
    { value: "wave", labelKey: "effect.wave" },
    { value: "breathe", labelKey: "effect.breathe" },
    { value: "prism", labelKey: "effect.prism" }
  ]

  function close() {
    opened = false
  }

  function selectModel(file) {
    if (!indicatorService) return
    indicatorService.setModelFile(file)
    for (var i = 0; i < modelCatalog.length; i++) {
      if (modelCatalog[i].file === file) {
        var valid = false
        for (var j = 0; j < modelCatalog[i].langs.length; j++) {
          if (modelCatalog[i].langs[j].code === currentLang) {
            valid = true
            break
          }
        }
        if (!valid && modelCatalog[i].langs.length > 0) {
          indicatorService.setLangCode(modelCatalog[i].langs[0].code)
        }
        break
      }
    }
  }

  function cycleModel() {
    for (var i = 0; i < modelCatalog.length; i++) {
      if (modelCatalog[i].file === currentModel) {
        var next = modelCatalog[(i + 1) % modelCatalog.length]
        selectModel(next.file)
        return
      }
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍬"
    active: root.isActive
    tooltipText: "TinyASR (" + root.currentLang.toUpperCase() + ") · " + root.activeModelEntry.label
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        if (root.indicatorService) root.indicatorService.preview()
      } else {
        root.opened = !root.opened
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher

    contentWidth: Math.min(Commons.Style.space(340), panel.availableCardWidth)
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === "1" && root.indicatorService) root.indicatorService.setIndicatorStyle("both")
        else if (t === "2" && root.indicatorService) root.indicatorService.setIndicatorStyle("edge")
        else if (t === "3" && root.indicatorService) root.indicatorService.setIndicatorStyle("pill")
        else if (t === "4" && root.indicatorService) root.indicatorService.setIndicatorStyle("none")
        else if (t === "m") root.cycleModel()
        else if (t === "b" && root.indicatorService) root.indicatorService.setBeamWidth(root.currentBeam === 4 ? 1 : 4)
        else if (t === "t" && root.indicatorService) root.indicatorService.preview()
        else if (t === "q") root.close()
      }
    }

    Column {
      id: contentColumn
      width: parent.width
      spacing: Commons.Style.space(10)

      // Header
      Row {
        width: parent.width
        spacing: Commons.Style.space(8)

        Text {
          textFormat: Text.PlainText
          text: strings.t("panel.title")
          color: Commons.Color.popups.text
          font.family: Commons.Style.font.family
          font.pixelSize: Commons.Style.font.subtitle
          font.bold: true
        }
      }

      // Section 1: Idioma
      Column {
        width: parent.width
        spacing: Commons.Style.space(4)

        Text {
          textFormat: Text.PlainText
          text: strings.t("section.language")
          color: Commons.Color.popups.text
          opacity: 0.7
          font.family: Commons.Style.font.family
          font.pixelSize: Math.max(10, Commons.Style.font.body - 2)
          font.weight: Font.Medium
        }

        Flow {
          width: parent.width
          spacing: Commons.Style.space(6)

          Repeater {
            model: root.activeModelEntry.langs

            delegate: Rectangle {
              id: langChip
              required property var modelData
              readonly property bool selected: root.currentLang === modelData.code

              width: langText.implicitWidth + Commons.Style.space(16)
              height: Commons.Style.space(28)
              radius: Commons.Style.space(6)
              color: selected
                ? Commons.Style.selectedAccentFill
                : (langHover.containsMouse ? Commons.Style.hoverFill : Commons.Style.normalFill)
              border.width: selected ? 1 : 0
              border.color: Commons.Color.accent

              Text {
                id: langText
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: langChip.modelData.code === "auto" ? strings.t("lang.auto") : langChip.modelData.label
                color: Commons.Color.popups.text
                font.family: Commons.Style.font.family
                font.pixelSize: Math.max(10, Commons.Style.font.body - 1)
                font.weight: langChip.selected ? Font.DemiBold : Font.Normal
              }

              MouseArea {
                id: langHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.indicatorService) root.indicatorService.setLangCode(langChip.modelData.code)
                }
              }
            }
          }
        }
      }

      // Section 2: Modelo
      Column {
        width: parent.width
        spacing: Commons.Style.space(4)

        Text {
          textFormat: Text.PlainText
          text: strings.t("section.model")
          color: Commons.Color.popups.text
          opacity: 0.7
          font.family: Commons.Style.font.family
          font.pixelSize: Math.max(10, Commons.Style.font.body - 2)
          font.weight: Font.Medium
        }

        Rectangle {
          width: parent.width
          height: Commons.Style.space(32)
          radius: Commons.Style.space(8)
          color: modelHover.containsMouse ? Commons.Style.hoverFill : Commons.Style.normalFill
          border.width: 1
          border.color: Commons.Style.normalBorderColor

          Row {
            anchors.fill: parent
            anchors.leftMargin: Commons.Style.space(10)
            anchors.rightMargin: Commons.Style.space(10)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - Commons.Style.space(20)
              textFormat: Text.PlainText
              text: root.activeModelEntry.label + "  (" + root.activeModelEntry.file + ")"
              color: Commons.Color.popups.text
              font.family: Commons.Style.font.family
              font.pixelSize: Math.max(10, Commons.Style.font.body - 1)
              elide: Text.ElideRight
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: "󰅀"
              color: Commons.Color.popups.text
              opacity: 0.7
              font.family: Commons.Style.font.family
              font.pixelSize: Commons.Style.font.body
            }
          }

          MouseArea {
            id: modelHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycleModel()
          }
        }
      }

      // Section 3: Qualidade (Beam)
      Column {
        width: parent.width
        spacing: Commons.Style.space(4)

        Text {
          textFormat: Text.PlainText
          text: strings.t("section.decoding")
          color: Commons.Color.popups.text
          opacity: 0.7
          font.family: Commons.Style.font.family
          font.pixelSize: Math.max(10, Commons.Style.font.body - 2)
          font.weight: Font.Medium
        }

        Row {
          width: parent.width
          spacing: Commons.Style.space(6)

          Repeater {
            model: [
              { beam: 4, labelKey: "beam.accurate" },
              { beam: 1, labelKey: "beam.fast" }
            ]

            delegate: Rectangle {
              id: beamChip
              required property var modelData
              readonly property bool selected: root.currentBeam === modelData.beam

              width: (contentColumn.width - Commons.Style.space(6)) / 2
              height: Commons.Style.space(28)
              radius: Commons.Style.space(6)
              color: selected
                ? Commons.Style.selectedAccentFill
                : (beamHover.containsMouse ? Commons.Style.hoverFill : Commons.Style.normalFill)
              border.width: selected ? 1 : 0
              border.color: Commons.Color.accent

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: strings.t(beamChip.modelData.labelKey)
                color: Commons.Color.popups.text
                font.family: Commons.Style.font.family
                font.pixelSize: Math.max(10, Commons.Style.font.body - 1)
                font.weight: beamChip.selected ? Font.DemiBold : Font.Normal
              }

              MouseArea {
                id: beamHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.indicatorService) root.indicatorService.setBeamWidth(beamChip.modelData.beam)
                }
              }
            }
          }
        }
      }

      // Section 4: Indicador Visual
      Column {
        width: parent.width
        spacing: Commons.Style.space(4)

        Text {
          textFormat: Text.PlainText
          text: strings.t("section.indicator")
          color: Commons.Color.popups.text
          opacity: 0.7
          font.family: Commons.Style.font.family
          font.pixelSize: Math.max(10, Commons.Style.font.body - 2)
          font.weight: Font.Medium
        }

        Grid {
          width: parent.width
          columns: 2
          spacing: Commons.Style.space(6)

          Repeater {
            model: root.styleOptions

            delegate: Rectangle {
              id: styleChip
              required property var modelData
              readonly property bool selected: root.currentStyle === modelData.value

              width: (contentColumn.width - Commons.Style.space(6)) / 2
              height: Commons.Style.space(28)
              radius: Commons.Style.space(6)
              color: selected
                ? Commons.Style.selectedAccentFill
                : (styleHover.containsMouse ? Commons.Style.hoverFill : Commons.Style.normalFill)
              border.width: selected ? 1 : 0
              border.color: Commons.Color.accent

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: strings.t(styleChip.modelData.labelKey)
                color: Commons.Color.popups.text
                font.family: Commons.Style.font.family
                font.pixelSize: Math.max(10, Commons.Style.font.body - 1)
                font.weight: styleChip.selected ? Font.DemiBold : Font.Normal
              }

              MouseArea {
                id: styleHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.indicatorService) root.indicatorService.setIndicatorStyle(styleChip.modelData.value)
                }
              }
            }
          }
        }
      }

      // Section 5: Efeito do glow
      Column {
        width: parent.width
        spacing: Commons.Style.space(4)
        visible: root.currentStyle === "both" || root.currentStyle === "edge"

        Text {
          textFormat: Text.PlainText
          text: strings.t("section.glowEffect")
          color: Commons.Color.popups.text
          opacity: 0.7
          font.family: Commons.Style.font.family
          font.pixelSize: Math.max(10, Commons.Style.font.body - 2)
          font.weight: Font.Medium
        }

        Grid {
          width: parent.width
          columns: 2
          spacing: Commons.Style.space(6)

          Repeater {
            model: root.effectOptions

            delegate: Rectangle {
              id: effectChip
              required property var modelData
              readonly property bool selected: root.currentEffect === modelData.value

              width: (contentColumn.width - Commons.Style.space(6)) / 2
              height: Commons.Style.space(28)
              radius: Commons.Style.space(6)
              color: selected
                ? Commons.Style.selectedAccentFill
                : (effectHover.containsMouse ? Commons.Style.hoverFill : Commons.Style.normalFill)
              border.width: selected ? 1 : 0
              border.color: Commons.Color.accent

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: strings.t(effectChip.modelData.labelKey)
                color: Commons.Color.popups.text
                font.family: Commons.Style.font.family
                font.pixelSize: Math.max(10, Commons.Style.font.body - 1)
                font.weight: effectChip.selected ? Font.DemiBold : Font.Normal
              }

              MouseArea {
                id: effectHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.indicatorService) root.indicatorService.setGlowEffect(effectChip.modelData.value)
                }
              }
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: Commons.Style.space(30)
        radius: Commons.Style.space(8)
        color: testHover.containsMouse ? Commons.Style.hoverFill : Commons.Style.normalFill
        opacity: root.currentStyle === "none" ? 0.45 : 1.0

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: strings.t("action.test")
          color: Commons.Color.popups.text
          font.family: Commons.Style.font.family
          font.pixelSize: Math.max(10, Commons.Style.font.body - 2)
          font.weight: Font.Medium
        }

        MouseArea {
          id: testHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: root.currentStyle !== "none"
          onClicked: {
            if (root.indicatorService) root.indicatorService.preview()
          }
        }
      }
    }
  }
}
