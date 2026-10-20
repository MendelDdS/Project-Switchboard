class_name Intro
extends ColorRect
## Tela inicial do turno: a sala escurecida e o recado do supervisor num bilhete preso com fita no painel da mesa
## comutadora (`over`): o nome da central impresso, a noite datilografada (`[typed]`) e o recado à mão, na caneta azul
## (`[hand]`, `PaperInk`); embaixo, os botões e, num papel como o da dica do manual, como se joga. Começando o turno,
## o bilhete some e a sala clareia (`FADE_SEC`).

signal start_pressed
signal settings_pressed
signal skip_pressed

const FADE_SEC := 1.2
const NOTE_AT := 0.3   ## a altura do bilhete no painel (fração do vão que sobra embaixo dele)
const INK := preload("res://scripts/ui/paper_ink.gd")

var over: Control   ## onde o bilhete fica preso: a mesa comutadora (o Main põe)
var _n := 0
var _night: Night
var _warned := false


func _ready() -> void:
	$Version.text = Settings.version_text()
	var hand := INK.new()
	hand.bbcode = "hand"
	%Date.install_effect(INK.new())
	%Text.install_effect(hand)
	%Start.pressed.connect(_start)
	%Settings.pressed.connect(settings_pressed.emit)
	%Skip.pressed.connect(skip_pressed.emit)
	%Reset.pressed.connect(func():
		Progress.clear()
		Main.restart())


## O bilhete preso no painel da mesa comutadora, no meio dele, e os botões logo embaixo (a mesa se arruma na tela).
func _process(_delta: float) -> void:
	if over == null:
		return
	var r := over.get_global_rect()
	var note: Control = %Note
	note.global_position = Vector2(r.get_center().x - note.size.x / 2.0, r.position.y + (r.size.y - note.size.y) * NOTE_AT).round()
	%Bottom.global_position = note.global_position + Vector2(0, note.size.y + 14)


## `can_skip`: jogo salvo (não uma noite forçada); no treinamento, dá para pular direto para a noite 1.
## `warned`: a noite anterior foi Insuficiente, e o bilhete lembra que esta decide.
func setup(n: int, night: Night, can_reset: bool, can_skip: bool, warned := false) -> void:
	_n = n
	_night = night
	_warned = warned
	%Reset.visible = can_reset
	%Skip.visible = can_skip and n == 0
	_texts()


## Começa o turno: os botões saem na hora (sem segundo clique) e o bilhete some com a sala clareando; o mouse já
## passa para a mesa.
func _start() -> void:
	%Bottom.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_pressed.emit()
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "color:a", 0.0, FADE_SEC)
	tw.tween_property(%Note, "modulate:a", 0.0, FADE_SEC * 0.6)
	tw.chain().tween_callback(func():
		visible = false
		set_process(false))


## O idioma pode mudar nas configurações com esta tela aberta.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _night != null:
		_texts()


func _texts() -> void:
	var night := _night
	var n := _n
	var date: String
	if n == 0:
		date = T.text(T.Key.INTRO_TRAINING) % [GameData.date_text(n), Main.fmt(0.0)]
	else:
		date = T.text(T.Key.INTRO_NIGHT) % [n, GameData.date_text(n), Main.fmt(0.0)]
	%Date.text = "[typed]%s[/typed]" % date
	var note := tr(night.note)
	if _warned:
		note += "\n\n" + tr(GameData.CONTENT.low_warning)
	%Text.text = "[hand]%s[/hand]" % note
	%Info.text = "[color=#8a2a1c]%s[/color]  %s" % [T.text(T.Key.HINT_BADGE), T.text(T.Key.INTRO_INFO)]   # como a dica do manual na parede
