extends Control
## A tela inicial do jogo, antes da primeira noite da sessão (o `GameView` a põe no lugar do `Main`; a pausa do jogo
## volta para ela por "Voltar ao menu"): à direita, o canto da mesa comutadora de perto com o FONE na entrada 1
## (`title_board.gd`); à esquerda, o nome do jogo, o menu (cada opção com uma lâmpada que acende na escolhida, pelo
## mouse ou pelas setas), os Créditos e a versão. Ao fundo, o ambiente da sala e, de vez em quando, uma linha
## chamando. Carregar e Novo jogo trocam o menu, no mesmo lugar, pelos jogos salvos (`%SlotMenu`, `Progress.SLOTS`,
## cada um com a noite em que parou): Carregar abre o escolhido ou o apaga (a lixeira); Novo jogo começa num vazio
## ou por cima de um usado. Apagar e sobrescrever perguntam antes, num papel como o dos créditos (`_ask`). Começar apaga a lâmpada do FONE, escurece a tela e clareia
## já no jogo.

const MAIN := "res://scenes/main.tscn"
const BOARD := preload("res://scripts/ui/title_board.gd")
const RING_GAP := Vector2(25.0, 50.0)   ## de quanto em quanto tempo (s, sorteado) uma linha chama...
const RING_SEC := 4.5   ## ...e quanto tempo ela fica chamando (dois toques) antes de desistir
const FADE_SEC := 0.9   ## o escuro ao começar o jogo (e o clarear, já nele)
const LOGO_GAP := 8   ## px entre as duas linhas do nome
const RAIN_CHANCE := 0.35   ## a chance de o ambiente ser de chuva
## A lixeira do botão de apagar um jogo salvo (`PixelArt.art`).
const TRASH: Array[String] = [
	"...###...",
	"#########",
	".........",
	".#######.",
	".#.#.#.#.",
	".#.#.#.#.",
	".#.#.#.#.",
	".#.#.#.#.",
	".#.#.#.#.",
	".#######.",
]

enum Pick { NONE, LOAD, NEW }

var _leaving := false
var _picking := Pick.NONE   ## os jogos salvos no lugar do menu: para carregar ou para o jogo novo
var _confirm := Callable()   ## perguntando no papel (`_ask`): o que o botão âmbar faz
var _ring := Timer.new()


func _ready() -> void:
	%Load.visible = _saved()
	%Quit.visible = OS.get_name() != "Web"   # (no navegador, sair do jogo não fecha nada)
	var lamp: ImageTexture = BOARD.lamp_art()
	for b: Button in [%Load, %New, %Settings, %Quit]:
		b.icon = lamp   # a lâmpada apagada; na escolhida, acesa (as cores do ícone na variação `TitleButton`)
	for b: Button in [%Load, %New, %Settings, %Quit, %Credits]:
		b.mouse_entered.connect(b.grab_focus)   # o mouse escolhe como as setas: uma lâmpada acesa só
	%Version.texture = PixelArt.tiny(Settings.version_text())
	_texts()
	for b: Button in [%Load, %New, %Quit, %Credits]:   # outra opção escolhida fecha as configurações abertas ao lado
		b.pressed.connect(func(): if %PauseMenu.visible: %PauseMenu.close_settings())
	%Load.pressed.connect(_slots.bind(Pick.LOAD))
	%New.pressed.connect(_slots.bind(Pick.NEW))
	%Back.pressed.connect(_slots.bind(Pick.NONE))
	%Back.icon = lamp
	%Back.mouse_entered.connect(%Back.grab_focus)
	%Settings.toggle_mode = true   # as configurações abrem ao lado do menu, com a lâmpada dela acesa
	%Settings.pressed.connect(func():
		if %PauseMenu.visible:
			%PauseMenu.close_settings()
		else:
			%PauseMenu.open_settings(false))
	%Quit.pressed.connect(get_tree().quit)
	%Credits.pressed.connect(_paper)
	%Erase.pressed.connect(func(): _confirm.call())
	%Close.pressed.connect(func():
		Sfx.play("click")
		_close_paper())
	for n in range(1, Progress.SLOTS + 1):
		var slot := _slot(n)
		var del := _delete(n)
		slot.icon = lamp
		del.icon = PixelArt.art(TRASH, {"#": Color.WHITE})   # (as cores do ícone, na variação `TitleButton`)
		slot.pressed.connect(_pick.bind(n))
		slot.mouse_entered.connect(func(): if not slot.disabled: slot.grab_focus())
		del.mouse_entered.connect(del.grab_focus)
		del.pressed.connect(func():
			_ask(T.Key.TITLE_DELETE_WARNING, "TITLE_DELETE", func():
				Progress.clear(n)
				%Load.visible = _saved()
				if not %Load.visible:
					_picking = Pick.NONE
				_close_paper()))
	%PauseMenu.visibility_changed.connect(func():
		var on: bool = %PauseMenu.visible
		%Settings.set_pressed_no_signal(on)
		if not on:
			_choose())
	Sfx.ring_stop()
	Sfx.muffle(false)
	Sfx.start_ambience("rain" if randf() < RAIN_CHANCE else "clear")
	add_child(_ring)
	_ring.one_shot = true
	_ring.timeout.connect(_toggle_ring)
	_ring.start(randf_range(RING_GAP.x, RING_GAP.y))
	_choose.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("pause"):
		return
	if %Shade.visible:
		get_viewport().set_input_as_handled()
		_close_paper()
	elif _picking != Pick.NONE:
		get_viewport().set_input_as_handled()
		_slots(Pick.NONE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_texts()


## O que se monta com o idioma: o nome do jogo em letra grande.
func _texts() -> void:
	# ponytail: a última palavra do nome ("Ruído", "Noise") em letra de 4× e o resto em 2×, em cima; um idioma em que
	# a palavra forte não venha no fim pede outra regra.
	var title := T.text(T.Key.GAME_TITLE)
	var cut := title.rfind(" ")
	var rest := title.left(maxi(cut, 0))
	var small: Image = BOARD.logo_art(rest, 1).get_image()
	var big: Image = BOARD.logo_art(title.substr(cut + 1), 2).get_image()
	var imgs: Array = [small, big] if cut > 0 else [big]
	var h := 0
	var w := 0
	for i: Image in imgs:
		w = maxi(w, i.get_width())
		h += i.get_height() + LOGO_GAP
	var logo := Image.create(w, h - LOGO_GAP, false, Image.FORMAT_RGBA8)
	var y := 0
	for i: Image in imgs:
		i.convert(Image.FORMAT_RGBA8)
		logo.blit_rect(i, Rect2i(Vector2i.ZERO, i.get_size()), Vector2i(0, y))
		y += i.get_height() + LOGO_GAP
	%Logo.texture = ImageTexture.create_from_image(logo)


## Há algum jogo salvo.
func _saved() -> bool:
	return range(1, Progress.SLOTS + 1).any(func(n: int): return FileAccess.file_exists(Progress.file(n)))


## O botão do jogo salvo `n` e a lixeira dele.
func _slot(n: int) -> Button:
	return %Slots.get_child(n - 1).get_node("Line/Slot")


func _delete(n: int) -> Button:
	return %Slots.get_child(n - 1).get_node("Line/Delete")


## A noite em que o jogo salvo `n` parou, com a data ("Noite 4 · Quinta-feira, 11 de outubro de 1973"); vazio, "".
## Lido direto do arquivo: o `Progress.load_saved` guarda ao lado o save que não dá para ler, e isso fica para o
## `Main` avisar.
func _where(n: int) -> String:
	var f := ConfigFile.new()
	if f.load(Progress.file(n)) != OK:
		return ""
	var night: int = f.get_value("progress", "night", 0)
	if night == 0:
		return T.text(T.Key.TITLE_WHERE_TRAINING) % GameData.date_text(0)
	return T.text(T.Key.TITLE_WHERE) % [night, GameData.date_text(night)]


## A primeira opção à mostra fica escolhida (as setas e o Enter andam a partir dela).
func _choose() -> void:
	if _leaving or %Shade.visible or _picking != Pick.NONE:
		return
	for b: Button in [%Load, %New]:
		if b.visible:
			b.grab_focus()
			return


## Uma linha começa a chamar (a lâmpada pulsando e a campainha do lado dela) ou, chamando, desiste.
func _toggle_ring() -> void:
	var board := $Board
	if board.ringing == 0:
		board.ringing = randi_range(2, board.COLS)
		var x: float = board.position.x + board.COL0 + board.PITCH * (board.ringing - 1)
		Sfx.ring_start({board.ringing: x / size.x})
		_ring.start(RING_SEC)
	else:
		board.ringing = 0
		Sfx.ring_stop()
		_ring.start(randf_range(RING_GAP.x, RING_GAP.y))


## Troca o menu pelos jogos salvos (`mode`: para carregar ou para o jogo novo) ou os devolve (`Pick.NONE`).
func _slots(mode: Pick) -> void:
	Sfx.play("click")
	_picking = mode
	_show_slots()


## Monta os jogos salvos no lugar do menu: a noite em que cada um parou e a data embaixo, ou "Vazio" (que não se
## carrega); a lixeira só para carregar, nos usados.
func _show_slots() -> void:
	var on := _picking != Pick.NONE
	$Menu.visible = not on
	%SlotMenu.visible = on
	if not on:
		_choose()
		return
	%Pick.text = T.text(T.Key.TITLE_PICK_LOAD if _picking == Pick.LOAD else T.Key.TITLE_PICK_NEW)
	var first: Button = %Back
	for n in range(Progress.SLOTS, 0, -1):
		var where := _where(n)
		var b := _slot(n)
		var date: Label = %Slots.get_child(n - 1).get_node("WhereBox/Where")
		b.text = "%d · %s" % [n, where.get_slice(" · ", 0) if where != "" else T.text(T.Key.TITLE_EMPTY)]
		b.disabled = _picking == Pick.LOAD and where == ""
		date.text = where.get_slice(" · ", 1)
		date.get_parent().visible = where != ""
		_delete(n).visible = _picking == Pick.LOAD and where != ""
		if not b.disabled:
			first = b
	first.grab_focus()


## O jogo salvo `n` escolhido: carrega; no jogo novo, começa nele (por cima do que houver, perguntando antes).
func _pick(n: int) -> void:
	if _picking == Pick.NEW and _where(n) != "":
		_ask(T.Key.TITLE_NEW_WARNING, "TITLE_ERASE", func():
			Progress.clear(n)
			_pick(n))
		return
	Progress.slot = n
	%Shade.visible = false
	_play()


## O papel dos créditos, por cima do menu.
func _paper() -> void:
	Sfx.play("click")
	%Text.text = T.text(T.Key.CREDITS_TEXT)
	%Erase.visible = false
	%Shade.visible = true
	%Close.grab_focus()


## A pergunta no papel, antes de apagar um jogo salvo: o botão âmbar (`label`, a chave do texto) faz `yes`; o Voltar
## vem escolhido.
func _ask(text: T.Key, label: String, yes: Callable) -> void:
	Sfx.play("click")
	_confirm = yes
	%Text.text = T.text(text)
	%Erase.text = label
	%Erase.visible = true
	%Shade.visible = true
	%Close.grab_focus()


## Fecha o papel e volta ao que estava atrás: o menu ou os jogos salvos.
func _close_paper() -> void:
	%Shade.visible = false
	_confirm = Callable()
	_show_slots()


## Troca esta tela pelo jogo (o `Main` lê o jogo salvo, se houver; os recomeços dele, `Main.restart`, não voltam
## aqui): o tec da chave, a lâmpada do FONE apagando, a tela escurecendo e, já com o jogo atrás, clareando.
func _play() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play("sw")
	Sfx.ring_stop()
	Sfx.stop_ambience(FADE_SEC)
	_ring.stop()
	$Board.ringing = 0
	$Board.fone_on = false
	%Fade.mouse_filter = Control.MOUSE_FILTER_STOP   # nada mais se clica no menu
	get_viewport().gui_release_focus()
	var dark := create_tween()
	dark.tween_interval(0.25)   # a lâmpada apagando
	dark.tween_property(%Fade, "color:a", 1.0, FADE_SEC)
	await dark.finished
	GameView.playing = true
	add_sibling(load(MAIN).instantiate())
	get_parent().move_child(self, -1)   # o escuro fica por cima do jogo enquanto clareia
	for c in get_children():
		if c is CanvasItem:
			c.visible = false
	var light := create_tween()
	light.tween_property(%Fade, "color:a", 0.0, FADE_SEC)
	await light.finished
	queue_free()
