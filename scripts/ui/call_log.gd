class_name CallLog
extends RichTextLabel
## Registro das conversas da noite, para consulta: tudo o que foi dito com o FONE na linha, ligação por ligação, na
## ordem em que tocaram (o telefone mostra só as últimas falas da ligação em foco). Lê as transcrições das próprias
## ligações (`track`) e se refaz quando alguma muda, no máximo uma vez por quadro e só aberto: as falas chegam letra a
## letra. Conversa que terminou com ele guardado fica "não lida" (`filed`, `unread_changed`: a folha nova na prancheta
## da mesa) até abri-lo.

signal unread_changed(on: bool)

const HEAD := 24.0   ## o espaço do cabeçalho impresso no alto da folha (`PaperDeco.HEAD_Y`): o texto começa abaixo dele
const SIDE := 6.0    ## dos lados, para o texto alinhar com o título e o fio do cabeçalho (`PaperDeco`, a 22 px da beira; a margem da cena dá 16)

var unread := false
var _calls: Array[PhoneCall] = []
var _dirty := false


func _ready() -> void:
	var box := StyleBoxEmpty.new()
	box.content_margin_top = HEAD
	box.content_margin_left = SIDE
	box.content_margin_right = SIDE
	add_theme_stylebox_override("normal", box)


## Passa a registrar a ligação `c` (o Main chama quando ela toca).
func track(c: PhoneCall) -> void:
	if c in _calls:
		return
	_calls.append(c)
	c.transcript_changed.connect(func(): _dirty = true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_TRANSLATION_CHANGED:
		_dirty = true


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_set_unread(false)
		if _dirty:
			_dirty = false
			_render()


## A ligação `c` terminou (o Main avisa): a conversa dela vai para o registro como folha nova, se houve conversa.
func filed(c: PhoneCall) -> void:
	if c in _calls and not c.transcript.is_empty() and not is_visible_in_tree():
		_set_unread(true)


func _set_unread(on: bool) -> void:
	if on != unread:
		unread = on
		unread_changed.emit(on)


func _render() -> void:
	var s := ""
	for c in _calls:
		if c.transcript.is_empty():
			continue
		var head := T.text(T.Key.LOG_DIALED) % c.target if c.kind == PhoneCall.Kind.OUTGOING else T.text(T.Key.STATUS_LINE) % c.line   # (a feita pelo operador não tem entrada)
		var out := "[color=#3f6a2c]↗[/color] " if c.kind == PhoneCall.Kind.OUTGOING else ""   # a marca da ligação feita: a seta saindo, na tinta do operador
		s += "%s[color=#5a4d3a]— %s · %s —[/color]\n" % [out, head, c.time]
		for l in c.transcript:
			var text := String(l["text"]).replace("[", "(")
			match l["cls"]:
				"sys":
					s += "[color=#5a4d3a]%s[/color]\n" % text
				"op":
					s += "[color=#3f6a2c]%s[/color]  %s\n" % [T.text(T.Key.YOU), text]
				_:
					s += "[color=#6e1a12]%s[/color]  %s\n" % [tr(l["who"]), text]
		s += "\n"
	text = s if s != "" else "[color=#5a4d3a]%s[/color]" % T.text(T.Key.CALL_LOG_EMPTY)
