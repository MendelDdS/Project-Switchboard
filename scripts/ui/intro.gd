class_name Intro
extends ColorRect
## Tela inicial do turno: a sala escurecida e o recado do supervisor (`SupervisorNote`) de perto, em cima do painel
## da mesa comutadora (`over`); embaixo, os botões e, num papel como o da dica do manual, como se joga. Começando o
## turno, o bilhete some e a sala clareia (`FADE_SEC`). Durante o turno, o bilhete pregado no quadro de avisos é lido
## de novo aqui (`reread`): ele vem do quadro, sem os botões, e o clique ou o Esc o devolve (`put_back`).

signal start_pressed
signal settings_pressed
signal skip_pressed

const FADE_SEC := 1.2
const NOTE_AT := 0.3   ## a altura do bilhete no painel (fração do vão que sobra embaixo dele)
const READ_SEC := 0.2   ## relendo, o bilhete vem do quadro e volta para ele nesse tempo (o das ferramentas, `Tools.SLIDE_SEC`)

var over: Control   ## onde o bilhete fica preso: a mesa comutadora (o Main põe)
var _n := 0
var _night: Night
var _warned := false
var _tapes := {}
var _aside := ""
var _flags: StoryFlags   ## os marcadores do roteiro (a versão do bilhete, `Night.note_for`)
var _code := ""   ## o código de autorização da noite (B3), quando a regra vale
var reading := false   ## relendo o bilhete do quadro, durante o turno
var _from := Rect2()   ## de onde ele veio relendo: o bilhete pregado no quadro (px da tela)
var _grow := 1.0       ## 0 no quadro, 1 de perto
var _dim := 0.0        ## o escuro da sala por trás (a cor da cena)
var _read: Tween


func _ready() -> void:
	$Version.text = Settings.version_text()
	_dim = color.a
	%Start.pressed.connect(_start)
	%Settings.pressed.connect(settings_pressed.emit)
	%Skip.pressed.connect(skip_pressed.emit)


## O bilhete preso no painel da mesa comutadora, no meio dele, e os botões logo embaixo (a mesa se arruma na tela).
func _process(_delta: float) -> void:
	if over == null:
		return
	var r := over.get_global_rect()
	var note: Control = %Note
	var at := Vector2(r.get_center().x - note.size.x / 2.0, r.position.y + (r.size.y - note.size.y) * NOTE_AT).round()
	var s := lerpf(_from.size.x / note.size.x, 1.0, _grow) if _from.has_area() else 1.0
	note.scale = Vector2(s, s)
	note.global_position = _from.position.lerp(at, _grow).round() if _from.has_area() else at
	%Bottom.global_position = at + Vector2(0, note.size.y + 14)


## `can_skip`: jogo salvo (não uma noite forçada); no treinamento, dá para pular direto para a noite 1.
## `warned`: a noite anterior foi Insuficiente, e o bilhete lembra que esta decide. `tapes`: o resumo das fitas da
## noite anterior (`Tapes.last`, B4), num parágrafo a mais. `aside`: o save que não deu para ler, guardado ao lado
## (`Progress.aside`), avisado no papel de como se joga. `code`: o código de autorização da noite (B3), no fim do bilhete.
func setup(n: int, night: Night, can_skip: bool, warned := false, tapes := {}, aside := "", flags: StoryFlags = null,
		code := "") -> void:
	_aside = aside
	_code = code
	_flags = flags
	_n = n
	_night = night
	_warned = warned
	_tapes = tapes
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


## Durante o turno, o bilhete pregado no quadro de avisos (`from`, px da tela) vem para perto, sem os botões.
func reread(from: Rect2) -> void:
	reading = true
	_from = from
	%Bottom.visible = false
	$Version.visible = false
	%Note.modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	set_process(true)
	Sfx.play("page")
	_slide(1.0)


## Devolve o bilhete relido ao quadro.
func put_back() -> void:
	if not reading:
		return
	reading = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Sfx.play("page")
	_slide(0.0).chain().tween_callback(func():
		visible = false
		set_process(false))


func _slide(to: float) -> Tween:
	if _read:
		_read.kill()
	_read = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if to > 0.0 else Tween.EASE_IN)
	_read.tween_property(self, "_grow", to, READ_SEC).from(1.0 - to)
	_read.tween_property(self, "color:a", _dim * to, READ_SEC)
	return _read


## Relendo, o clique em qualquer lugar devolve o bilhete.
func _gui_input(e: InputEvent) -> void:
	if reading and e is InputEventMouseButton and not e.pressed:
		accept_event()
		put_back()


## O idioma pode mudar nas configurações com esta tela aberta.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _night != null:
		_texts()


func _texts() -> void:
	var extra := PackedStringArray()
	if _warned:
		extra.append(tr(GameData.CONTENT.low_warning))
	var tapes := Bureaucracy.Tapes.note(_tapes, _n)
	if tapes != "":
		extra.append(tapes)
	if _code != "":
		extra.append(T.text(T.Key.CODE_NOTE) % _code)
	%Note.write(_n, _night, _flags, extra)
	%Info.text = "[color=#8a2a1c]%s[/color]  %s" % [T.text(T.Key.HINT_BADGE), T.text(T.Key.INTRO_INFO)]   # como a dica do manual na parede
	if _aside != "":
		%Info.text = "[color=#8a2a1c]%s[/color]  %s" % [T.text(T.Key.SAVE_ASIDE_BADGE), T.text(T.Key.SAVE_ASIDE) % _aside.get_file()]
