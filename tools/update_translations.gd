extends SceneTree
## Atualiza as traduções. Rode depois de mexer em textos (interface ou falas):
##   Godot --headless --path . -s tools/update_translations.gd
##
## 1. Interface e código: gera scripts/t.gd (enum T.Key) a partir das chaves de translations/ui.csv.
##    Para um texto novo: acrescente uma linha no CSV (chave, pt_BR, en, es) e rode este script.
## 2. Falas dos roteiros: percorre o conteúdo (data/content.tres e tudo o que ele referencia), escreve
##    translations/content.pot e atualiza translations/content.<idioma>.po mantendo o que já foi traduzido.
##    Falas novas entram com msgstr vazio (o jogo mostra o português até alguém traduzir); as que sumiram saem.
##    Todo campo de texto dos Resources entra, exceto os de SKIP (nomes próprios, números, ids, marcadores).
## 3. Revisão: `-- --review` grava também build/traducoes.csv, uma fala por linha (arquivo, pt_BR, en, es), para
##    abrir numa planilha; corrigida, `-- --apply=build/traducoes.csv` devolve as colunas en e es aos .po (o pt_BR
##    não volta: ele mora nos Resources; célula vazia não apaga a tradução).

const UI_CSV := "res://translations/ui.csv"
const ENUM_SCRIPT := "res://scripts/t.gd"
const POT := "res://translations/content.pot"
const LANGS := ["en", "es"]
const REVIEW := "res://build/traducoes.csv"
## Campos que não se traduzem: nomes próprios (contatos, ruas, endereços) e dados internos.
const SKIP := ["name", "address", "number", "category", "target", "alt_target", "street", "id", "voice", "voices", "effect", "weather", "kind", "teacher", "teacher_voice", "until",
	"fake_address", "caller_name", "caller_names", "message_to", "from_number", "urgency_reason", "deal_from", "deal_to", "deal_signal", "secret_signal", "block_labels", "units", "worsening_units", "critical_units", "lost_units", "requires", "sets", "overheard_sets", "overheard_flags", "if_connected", "if_elsewhere", "if_dropped", "if_missed", "if_hung_up", "if_delivered", "if_sebastiao", "key", "detail", "news_photo", "photo", "resource_name", "resource_path", "resource_scene_unique_id"]

var _ids := {}   ## msgid -> Array de arquivos onde aparece (em ordem de descoberta)
var _fixes := {}  ## idioma -> {msgid: tradução} da tabela de revisão (`--apply`)


func _initialize() -> void:
	_write_enum()
	_visit(load("res://data/content.tres"), "res://data/content.tres", {})
	_write_pot()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--apply="):
			_read_review(arg.trim_prefix("--apply="))
	for lang in LANGS:
		_merge_po(lang)
	if "--review" in OS.get_cmdline_user_args():
		_write_review()
	quit(0)


# ---------------------------------------------------------------- enum da interface

func _write_enum() -> void:
	var f := FileAccess.open(UI_CSV, FileAccess.READ)
	f.get_csv_line()   # cabeçalho
	var keys := PackedStringArray()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > 0 and row[0] != "":
			keys.append(row[0])
	var s := "class_name T\n"
	s += "## Textos da interface e do código, por chave. GERADO por tools/update_translations.gd a partir de\n"
	s += "## translations/ui.csv (colunas pt_BR, en, es): não edite à mão; acrescente a linha no CSV e rode a ferramenta.\n"
	s += "## Uso: T.text(T.Key.START_SHIFT); com valores: T.text(T.Key.LINE_N) % n.\n"
	s += "## Nas cenas, o texto do Label/Button é a própria chave (ex.: \"START_SHIFT\") e o Godot traduz sozinho.\n\n"
	s += "enum Key {\n"
	for k in keys:
		s += "\t%s,\n" % k
	s += "}\n\n\n"
	s += "## `k` é um T.Key (int: o Godot não aceita T.Key e Key como o mesmo tipo dentro da própria classe).\n"
	s += "static func text(k: int) -> String:\n"
	s += "\treturn String(TranslationServer.translate(Key.find_key(k)))\n"
	FileAccess.open(ENUM_SCRIPT, FileAccess.WRITE).store_string(s)
	print("enum: %d chaves" % keys.size())


# ---------------------------------------------------------------- falas do conteúdo

func _visit(r: Resource, src: String, seen: Dictionary) -> void:
	if r == null or seen.has(r):
		return
	seen[r] = true
	if r.resource_path != "" and not "::" in r.resource_path:
		src = r.resource_path
	for p in r.get_property_list():
		if not (p["usage"] & PROPERTY_USAGE_STORAGE) or p["name"] in SKIP or p["name"] == "script":
			continue
		var v = r.get(p["name"])
		match typeof(v):
			TYPE_STRING:
				_add(v, src)
			TYPE_PACKED_STRING_ARRAY:
				for t in v:
					# quem liga: "voz:nome" (só o nome se traduz)
					_add(t.get_slice(":", 1) if p["name"] == "callers" else t, src)
			TYPE_OBJECT:
				if v is Resource:
					_visit(v, src, seen)
			TYPE_ARRAY:
				for item in v:
					if item is Resource:
						_visit(item, src, seen)
					elif item is PackedStringArray:   # Motive.talks
						for t in item:
							_add(t, src)
	# "o Hotel Serena" também aparece como "do Hotel Serena" e "pro Hotel Serena" (lacunas dos moldes)
	if r is DirectoryEntry and r.spoken != "":
		_add("d" + r.spoken, src)
		_add("pr" + r.spoken, src)


func _add(t: String, src: String) -> void:
	if t.strip_edges() == "":
		return
	if not _ids.has(t):
		_ids[t] = []
	if not src in _ids[t]:
		_ids[t].append(src)


func _write_pot() -> void:
	var s := _header("")
	for id in _ids:
		s += _entry(id, "")
	FileAccess.open(POT, FileAccess.WRITE).store_string(s)
	print("pot: %d falas" % _ids.size())


func _merge_po(lang: String) -> void:
	var path := "res://translations/content.%s.po" % lang
	var old := _read_po(path)
	var s := _header(lang)
	var missing := 0
	for id in _ids:
		var tr_text: String = _fixes.get(lang, {}).get(id, old.get(id, ""))
		if tr_text == "":
			missing += 1
		s += _entry(id, tr_text)
	FileAccess.open(path, FileAccess.WRITE).store_string(s)
	print("%s: %d falas, %d sem tradução" % [lang, _ids.size(), missing])


func _header(lang: String) -> String:
	var s := "msgid \"\"\nmsgstr \"\"\n\"Content-Type: text/plain; charset=UTF-8\\n\"\n"
	if lang != "":
		s += "\"Language: %s\\n\"\n" % lang
	return s + "\n"


func _entry(id: String, text: String) -> String:
	var refs := PackedStringArray()
	for src in _ids[id].slice(0, 3):
		refs.append(src.trim_prefix("res://"))
	return "#: %s\nmsgid %s\nmsgstr %s\n\n" % [" ".join(refs), _quote(id), _quote(text)]


func _quote(t: String) -> String:
	return "\"%s\"" % t.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t")


# ---------------------------------------------------------------- revisão em planilha

func _write_review() -> void:
	DirAccess.make_dir_recursive_absolute(REVIEW.get_base_dir())
	var tr_by := LANGS.map(func(l): return _read_po("res://translations/content.%s.po" % l))
	var f := FileAccess.open(REVIEW, FileAccess.WRITE)
	f.store_string("\uFEFF")   # a planilha reconhece os acentos (UTF-8)
	f.store_csv_line(PackedStringArray(["arquivo", "pt_BR"] + LANGS))
	for id in _ids:
		f.store_csv_line(PackedStringArray([_ids[id][0].trim_prefix("res://"), id] + tr_by.map(func(d): return d.get(id, ""))))
	print("revisão: %s (%d falas)" % [REVIEW.trim_prefix("res://"), _ids.size()])


func _read_review(path: String) -> void:
	var f := FileAccess.open(path if path.is_absolute_path() else "res://" + path, FileAccess.READ)
	if f == null:
		push_error("tabela de revisão não encontrada: " + path)
		return
	var head := f.get_csv_line()
	var cols := LANGS.map(func(l): return head.find(l))
	for l in LANGS:
		_fixes[l] = {}
	var changed := 0
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < head.size() or not _ids.has(row[1]):
			continue
		for i in LANGS.size():
			if row[cols[i]] != "":
				_fixes[LANGS[i]][row[1]] = row[cols[i]]
				changed += 1
	print("revisão aplicada: %d traduções lidas de %s" % [changed, path])


## msgid -> msgstr de um .po (aceita strings em várias linhas).
func _read_po(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		return out
	var cur := ""
	var id := ""
	var msg := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		line = line.strip_edges()
		if line.begins_with("msgid "):
			if id != "":
				out[id] = msg
			cur = "id"
			id = _unquote(line.trim_prefix("msgid "))
			msg = ""
		elif line.begins_with("msgstr "):
			cur = "str"
			msg = _unquote(line.trim_prefix("msgstr "))
		elif line.begins_with("\""):
			if cur == "id":
				id += _unquote(line)
			elif cur == "str":
				msg += _unquote(line)
	if id != "":
		out[id] = msg
	return out


func _unquote(q: String) -> String:
	return q.substr(1, q.length() - 2).c_unescape()
