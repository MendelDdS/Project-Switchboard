extends Node
## O diário de Maria (`Tools.DIARY`, aberto no `diary_view.gd`): as tarefas da noite, uma por linha, e as anotações
## dela (`Night.diary`, escritas quando acontece o fato; o balanço, no fim). Só lê o que o
## jogo já sabe (os pedidos do roteiro, `Night.tasks`, pelos marcadores; as normas que valem, `Bureaucracy.live`, as
## advertências da noite, as pendências da mesa): não decide nem cobra nada (a tarefa com X não é advertência; a cobrança é a de sempre, no relatório). As normas e a rotina só se
## resolvem no turno encerrado (quando aparece o botão Encerrar turno, `Main.last_call`), porque até lá sempre pode
## chegar mais uma; a rotina mostra quanto falta.

enum State { OPEN, DONE, FAILED }

signal changed   ## as tarefas mudaram (`tasks`)
signal added     ## entrou tarefa nova: o lápis atravessado em cima do diário da mesa, até abrir

const TAPES_RULE := "b4_fitas"   ## a norma das fitas traz a tarefa de entregá-las

## {"id", "text" (já traduzido), "src" (o original: o nome da chave `T.Key` com "ui", ou a fala em português),
## "ui", "left" (quanto falta, -1 sem conta) e "state" (`State`)}, na ordem da página.
var tasks: Array[Dictionary] = []
var notes: Array[Dictionary] = []   ## as anotações, como as tarefas (sem conta nem estado), na ordem em que foram escritas
var letter := ""   ## a carta da noite (em português; o Main põe): lida, fica guardada entre as páginas
var _logs := false      # já houve ligação por registrar nesta noite: a tarefa das fichas entra
var _tickets := false   # já saiu bilhete do calculógrafo nesta noite: a tarefa dos bilhetes entra
var _story := {}   # índice em `Night.tasks` -> `State`: as do roteiro já anotadas (riscada ou com X, fica assim)
var _written: Array[int] = []   # índices em `Night.diary` já escritos, na ordem

@onready var main: Main = get_parent()


## Refaz as tarefas (o Main chama a cada quadro do turno): avisa `changed` se algo mudou e `added` se entrou alguma.
func refresh() -> void:
	var closed := main.minutes >= main.last_call
	var out: Array[Dictionary] = []
	_story_tasks(out, closed)
	for r in main.bureaucracy.live():
		if r.task_text == "":
			continue
		var state := State.OPEN
		if closed:
			state = State.FAILED if main.report.faults.any(func(f: Dictionary) -> bool: return f.id == r.id) else State.DONE
		out.append({"id": r.id, "text": T.text(T.Key[r.task_text]), "src": r.task_text, "ui": true, "left": -1, "state": state})
	_logs = _logs or main.notebook.pending_count() > 0
	if _logs:
		_routine(out, "fichas", T.Key.DIARY_LOGS, main.notebook.pending_count(), closed)
	_tickets = _tickets or main.toll.waiting() > 0
	if _tickets:
		_routine(out, "bilhetes", T.Key.DIARY_TICKETS, main.toll.waiting(), closed)
	if main.bureaucracy.live().any(func(r: BureaucracyRule) -> bool: return r.id == TAPES_RULE):
		_routine(out, "fitas", T.Key.DIARY_TAPES, main.bureaucracy.tapes.unresolved().size(), closed)
	var wrote := _write_notes()
	if out == tasks and not wrote:
		return
	var fresh := wrote or out.any(func(t: Dictionary) -> bool: return not tasks.any(func(o: Dictionary) -> bool: return o.id == t.id))
	tasks = out
	changed.emit()
	if fresh:
		added.emit()


## Escreve as anotações da noite que chegaram na hora (`DiaryLine.due`); devolve se escreveu alguma.
func _write_notes() -> bool:
	if main.night == null:
		return false
	for n in notes:   # (no idioma de agora)
		n.text = tr(n.src)
	var before := _written.size()
	for i in main.night.diary.size():
		var l: Night.DiaryLine = main.night.diary[i]
		if i not in _written and l.due(main.flags, main.story_ends, main.background.letter_read, main.ending):
			_written.append(i)
			notes.append({"id": "nota_%d" % i, "text": tr(l.text), "src": l.text, "ui": false, "left": -1, "state": State.OPEN})
	return _written.size() > before


## Uma tarefa da rotina, com `left` pendentes: cumprida no turno encerrado sem nada pendente; com o turno fechando
## (`Main.ending`) e algo pendente, perdida.
func _routine(out: Array[Dictionary], id: String, key: T.Key, left: int, closed: bool) -> void:
	var state := State.OPEN
	if closed and left == 0:
		state = State.DONE
	elif main.ending and left > 0:
		state = State.FAILED
	out.append({"id": id, "text": T.text(key), "src": T.Key.find_key(key), "ui": true, "left": left, "state": state})


## Os pedidos do roteiro desta noite (`Night.tasks`): entram pelos marcadores (os da carta, depois de lida) e ficam;
## riscados na hora pelos marcadores, com X no prazo vencido; os de não fazer (`at_close`) só no turno encerrado.
func _story_tasks(out: Array[Dictionary], closed: bool) -> void:
	if main.night == null:
		return
	for i in main.night.tasks.size():
		var t: Night.DiaryTask = main.night.tasks[i]
		if not _story.has(i):
			if (t.letter and not main.background.letter_read) or not main.flags.allows(t.requires):
				continue
			_story[i] = State.OPEN
		var state: State = _story[i]
		if state == State.OPEN:
			var met := t.met(main.flags)
			if t.at_close:
				state = (State.DONE if met else State.FAILED) if closed else State.OPEN
			elif met:
				state = State.DONE
			elif (t.until >= 0.0 and main.minutes > t.until) or main.ending:
				state = State.FAILED
			if not t.at_close or closed:
				_story[i] = state
		out.append({"id": "roteiro_%d" % i, "text": tr(t.text), "src": t.text, "ui": false, "left": -1, "state": state})


## A página da noite como ficou, para o save (`Progress.diary`): as tarefas, as anotações e a carta lida, sem o texto
## traduzido, que volta por `text_of`.
func page() -> Dictionary:
	var keep := func(t: Dictionary) -> Dictionary: return {"src": t.src, "ui": t.ui, "left": t.left, "state": t.state}
	return {"tasks": tasks.map(keep), "notes": notes.map(keep), "letter": letter if main.background.letter_read else ""}


## O texto de uma tarefa guardada (`page`) no idioma de agora.
static func text_of(t: Dictionary) -> String:
	return T.text(T.Key[t.src]) if t.ui else TranslationServer.translate(t.src)
