class_name Pal
extends RefCounted
## Paleta e fontes compartilhadas.

const VOID := Color("050607")
const ROOM := Color("131a1d")
const PANEL := Color("2f2a21")
const PANEL_HI := Color("4b4332")
const PANEL_LO := Color("18150f")
const EDGE := Color("0b0a07")
const BRASS := Color("b8924e")
const PAPER := Color("d8caa3")
const PAPER_2 := Color("c2b288")
const PAPER_LINE := Color("b3a37a")
const INK := Color("2a2319")
const INK_SOFT := Color("5a4d3a")
const INK_RED := Color("6e1a12")
const AMBER := Color("f3a83c")
const GREEN := Color("8dbb6c")
const RED := Color("d4553f")
const GHOST := Color("cfe6d2")
const TEXT := Color("e6dbbd")
const DIM := Color("9a917a")
const GLOW := Color("ffd183")

## Fontes de pixel: importadas sem suavização e sem sub-pixel, e só ficam nítidas em alguns tamanhos (fora deles os
## traços ficam finos ou tortos). Use: `ui` (Pixelify Sans) em 11, 12, 14, 16, 18, 22; `mono` (VT323, números)
## em 20, 21, 25, 30, 35 (abaixo de 20 ela fica fina demais). O 2 e o 5 da Pixelify foram redesenhados (pareciam S e Z) e a
## fonte, fixada no peso Regular (era variável).
static var ui: Font = preload("res://fonts/PixelifySans.ttf")
static var mono: Font = preload("res://fonts/VT323-Regular.ttf")
