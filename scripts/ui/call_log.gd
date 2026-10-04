class_name CallLog
extends RichTextLabel
## Registro das conversas da noite, para consulta: tudo o que foi dito com o FONE na linha, ligação por ligação, na
## ordem em que tocaram (o telefone mostra só as últimas falas da ligação em foco). Lê as transcrições das próprias
## ligações (`track`) e se refaz quando alguma muda, no máximo uma vez por quadro e só aberto: as falas chegam letra a
## letra.

var _calls: Array[PhoneCall] = []
var _dirty := false


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
	if _dirty and is_visible_in_tree():
		_dirty = false
		_render()


func _render() -> void:
	var s := ""
	for c in _calls:
		if c.transcript.is_empty():
			continue
		s += "[color=#5a4d3a]— %s · %s —[/color]\n" % [T.text(T.Key.STATUS_LINE) % c.line, c.time]
		for l in c.transcript:
			var text := String(l["text"]).replace("[", "(")
			match l["cls"]:
				"sys":
					s += "[color=#5a4d3a]%s[/color]\n" % text
				"op":
					s += "[color=#3f6a2c]%s[/color]  %s\n" % [T.text(T.Key.YOU), text]
				"ghost":
					s += "[color=#6e1a12]—[/color]  %s\n" % text
				_:
					s += "[color=#6e1a12]%s[/color]  %s\n" % [tr(l["who"]), text]
		s += "\n"
	text = s if s != "" else "[color=#5a4d3a]%s[/color]" % T.text(T.Key.CALL_LOG_EMPTY)
