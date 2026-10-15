class_name Notebook
extends Control
## Aba do caderno de ocorrências. Cada ligação encerrada entra numa fila; o jogador registra quando puder, com um
## clique no tipo (o resto da linha o caderno já sabe). O livro é desenhado como página pautada (`_draw_page`).

## Quantas ocorrências esperam registro (a da ficha mais as da fila).
signal pending_changed(count: int)
## Uma ocorrência foi registrada: `rec` é o que a ligação gerou; `type` é o tipo que o jogador escolheu.
signal registered(rec: PhoneCall.Record, type: T.Key)

## Cor do carimbo de cada tipo no livro.
const STAMPS := {
	T.Key.TYPE_COMMON: Pal.LOG_STAMPS[0],
	T.Key.TYPE_EMERGENCY: Pal.LOG_STAMPS[1],
	T.Key.TYPE_PRANK: Pal.LOG_STAMPS[2],
	T.Key.TYPE_MISSED: Pal.LOG_STAMPS[3],
}
const ROW_H := 50.0                # cada ocorrência: linha principal e, abaixo, unidade e observação
const X_CALLER := 56.0             # colunas do livro (as legendas acima seguem as mesmas larguras)
const X_PLACE := 216.0
const X_STAMP := 360.0
const RULE := Pal.NOTE_RULE       # a pauta e a margem, as do caderno da mesa
const MARGIN := Pal.NOTE_MARGIN

var night := 1:   ## a noite do turno (o Main põe): a data no alto do livro
	set(v):
		night = v
		if is_node_ready():
			_date()
var entries: Array[PhoneCall.Record] = []   ## o livro: as registradas, com o carimbo
var pending: PhoneCall.Record              ## a da ficha (nula: nenhuma)
var queue: Array[PhoneCall.Record] = []

@onready var _scroll: ScrollContainer = %Scroll
@onready var _page: Control = %Page
@onready var _form: Control = %Form
@onready var _time: Label = %Time
@onready var _queue: Label = %Queue
@onready var _who: Label = %Who
@onready var _where: Label = %Where
@onready var _obs: Label = %Obs


func _ready() -> void:
	%Common.pressed.connect(register.bind(T.Key.TYPE_COMMON))
	%Emergency.pressed.connect(register.bind(T.Key.TYPE_EMERGENCY))
	%Prank.pressed.connect(register.bind(T.Key.TYPE_PRANK))
	_page.draw.connect(_draw_page)
	_page.resized.connect(_page.queue_redraw)
	_render_ledger()
	_fill()
	_date()


## O idioma mudou nas configurações: carimbos e títulos se refazem.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_page.queue_redraw()
		_fill()
		_date()


## A data da noite no alto do livro ("Noite de 8 para 9", `GameData.date_of`).
func _date() -> void:
	%Date.text = T.text(T.Key.NOTEBOOK_DATE) % [GameData.date_of(night).day, GameData.date_of(night, 1).day]


func has_pending() -> bool:
	return pending != null


func pending_count() -> int:
	return queue.size() + (1 if has_pending() else 0)


## Nova ocorrência. Se já há uma na ficha, entra na fila. Não atendida vai direto para o livro (não há tipo a
## escolher: ninguém falou com a pessoa).
func add(rec: PhoneCall.Record) -> void:
	if rec.missed:
		entries.append(rec.stamped(T.Key.TYPE_MISSED, ""))
		_render_ledger()
		return
	if pending == null:
		pending = rec
		_fill()
	else:
		queue.append(rec)
		_update_title()
	pending_changed.emit(pending_count())


## O registro mudou depois de entrar no caderno (ex.: unidades enviadas para a emergência).
func refresh_record(rec: PhoneCall.Record) -> void:
	if is_same(rec, pending):
		_fill()


## Registra a ocorrência da ficha com o tipo escolhido; a próxima da fila sobe para a ficha.
func register(type: T.Key) -> void:
	if pending == null:
		return
	var rec := pending
	entries.append(rec.stamped(type, rec.obs))
	pending = queue.pop_front() if not queue.is_empty() else null
	Sfx.play("pencil")
	_render_ledger()
	_fill()
	pending_changed.emit(pending_count())
	registered.emit(rec, type)


## Debug: caderno em branco.
func reset() -> void:
	entries.clear()
	queue.clear()
	pending = null
	_render_ledger()
	_fill()
	pending_changed.emit(0)


func _fill() -> void:
	_form.visible = has_pending()
	if not has_pending():
		return
	_update_title()
	_who.text = pending.who
	var where := pending.where
	if pending.card > 0:
		where += "  ·  " + T.text(T.Key.NOTEBOOK_CARD) % pending.card
	if pending.ticket > 0:
		where += "  ·  " + T.text(T.Key.NOTEBOOK_TICKET) % pending.ticket
	if pending.unit != "—":
		where += "  ·  " + pending.unit
	_where.text = where
	_obs.text = pending.obs
	_obs.visible = _obs.text != ""


func _update_title() -> void:
	if has_pending():
		_time.text = T.text(T.Key.NOTEBOOK_NEW) % pending.time
		_queue.text = T.text(T.Key.NOTEBOOK_QUEUE) % queue.size() if not queue.is_empty() else ""


## A página cresce com as ocorrências (rola); quando são poucas, a área de rolagem a estica até embaixo (expand
## na cena). A última fica à vista.
func _render_ledger() -> void:
	if not is_node_ready():
		return
	_page.custom_minimum_size.y = entries.size() * ROW_H
	_page.queue_redraw()
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


## Página pautada com margem vermelha; uma ocorrência por pauta: hora, quem, onde e o carimbo do tipo, e abaixo,
## menor, a unidade enviada e a observação.
func _draw_page() -> void:
	var w := _page.size.x
	var rows := ceili(_page.size.y / ROW_H)
	for k in rows:
		_page.draw_rect(Rect2(0, (k + 1) * ROW_H - 1, w, 1), RULE)
	_page.draw_rect(Rect2(X_CALLER - 8, 0, 1, _page.size.y), MARGIN)
	if entries.is_empty():
		_page.draw_string(Pal.ui, Vector2(X_CALLER, 28), T.text(T.Key.NOTEBOOK_EMPTY), HORIZONTAL_ALIGNMENT_LEFT, w - X_CALLER, 11, Pal.INK_SOFT)
		return
	for i in entries.size():
		var r := entries[i]
		var y := i * ROW_H
		var ink := Pal.INK
		_page.draw_string(Pal.mono, Vector2(4, y + 22), r.time, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
		_page.draw_string(Pal.mono, Vector2(X_CALLER, y + 22), _fit(Pal.mono, r.who, 11, X_PLACE - X_CALLER - 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
		_page.draw_string(Pal.mono, Vector2(X_PLACE, y + 22), _fit(Pal.mono, r.where, 11, X_STAMP - X_PLACE - 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
		_stamp(r.type, Rect2(X_STAMP, y + 5, w - X_STAMP - 4, 22))
		var notes := PackedStringArray()
		if r.card > 0:   # o número do cartão de despacho enviado
			notes.append(T.text(T.Key.NOTEBOOK_CARD) % r.card)
		if r.ticket > 0:   # o do bilhete de tarifação
			notes.append(T.text(T.Key.NOTEBOOK_TICKET) % r.ticket)
		if r.unit != "—":
			notes.append(T.text(T.Key.COL_UNIT) + ": " + r.unit)
		if r.obs != "":
			notes.append(r.obs)
		_page.draw_string(Pal.ui, Vector2(X_CALLER, y + 41), _fit(Pal.ui, "  ·  ".join(notes), 11, w - X_CALLER - 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.INK_SOFT)


## Carimbo do tipo: moldura e texto na cor dele, sobre um fundo levemente tingido.
func _stamp(type: T.Key, r: Rect2) -> void:
	var col: Color = STAMPS[type]
	_page.draw_rect(r, Color(col, 0.1))
	_page.draw_rect(r, col, false, 2.0)
	var txt := _fit(Pal.ui, T.text(type).to_upper(), 11, r.size.x - 8)
	_page.draw_string(Pal.ui, Vector2(r.position.x, r.position.y + 16), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, col)


## O texto, cortado com reticências se não couber em `w` px.
func _fit(f: Font, s: String, sz: int, w: float) -> String:
	if f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x <= w:
		return s
	while s.length() > 1 and f.get_string_size(s + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
		s = s.left(-1)
	return s.strip_edges() + "..."
