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

## Fontes vetoriais com suavização (IBM Plex, SIL OFL): ficam legíveis em qualquer tamanho de janela (as de pixel, sem
## suavização, perdiam os traços de 1 px com a janela menor que 1280×720). `ui` (Plex Sans Condensed) em 14 ou mais (12 só
## onde não cabe); `mono` (Plex Mono, números e papel) em 14 ou mais.
static var ui: Font = preload("res://fonts/IBMPlexSansCondensed-Regular.ttf")
static var mono: Font = preload("res://fonts/IBMPlexMono-Regular.ttf")
