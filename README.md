# TinyASR Dictation Indicator

An Omarchy Shell (`Quickshell`) plugin that provides an active-window **edge glow**, a floating **listening/transcribing pill**, and a **configuration panel** for [tinyasr](https://github.com/dkaraush/tinyasr) voice dictation.

## Features

- **Active-window indicator**: Renders a smooth pulsing edge glow and/or floating pill centered on the focused Hyprland window (with automatic screen fallback).
- **Theme-synced**: Uses `qs.Commons` (`Color.accent`, `Color.popups.*`, `Style.duration`, `Style.font`).
- **Bar widget & keyboard panel**:
  - **Language**: `PT`, `EN`, `ES`, `IT`, `PT+EN`, `Auto` (adapts to the selected model).
  - **Model** (`M`): Switch between `en-es-it-pt.tzf`, `en-ru-uk.tzf`, `uz.tzf`, `en-fa.tzf`, and `en-km.tzf`.
  - **Decoding** (`B`): Accurate (`Beam 4`) or Fast (`Greedy / Beam 1`).
  - **Visual indicator** (`1–4`): `Bordas + Pílula`, `Apenas bordas`, `Apenas pílula`, or `Nenhuma`.
  - **Preview** (`T` or right-click on the bar icon): 2-second animation preview.

## Requirements

- Omarchy with `omarchy-shell` and `hyprctl`.
- `python3` (used by `scripts/tinyasr-config` for bounded config/window I/O).
- A dictation adapter (such as `omarchy-dictation-tinyasr`) calling the plugin's IPC target `tinyasr-indicator`.

## Install

```bash
omarchy plugin add <repo-url> --enable
omarchy bar put dorneles.tinyasr-indicator --section right
```

## IPC

```bash
omarchy-shell tinyasr-indicator listening
omarchy-shell tinyasr-indicator transcribing
omarchy-shell tinyasr-indicator hide
omarchy-shell tinyasr-indicator preview
omarchy-shell tinyasr-indicator status
```

Settings are persisted under `~/.config/tinyasr/` (`indicator-style`, `model`, `lang`, `beam`).
