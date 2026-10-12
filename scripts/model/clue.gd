class_name Clue
extends RefCounted
## Uma palavra-chave ouvida na escuta (`Eavesdrop`). Nas falas escritas das conversas (`TransferCall.overheard`,
## `Motive.talks`) ela vai marcada como `[tipo:texto]` ("na [street:Rua do Sol], às [time:{hour}]"; a marca some da
## tela e da voz); o operador a pega se ouvir todas as letras dela. As pegas ficam em `Eavesdrop.clues`, de todas as
## noites (salvas no `Progress`, `to_dict`/`from_dict`), anotadas na página de anotações da lista telefônica
## (`PhoneBook`), onde o operador marca as que vai repassar a um interessado (o repasse ainda está por fazer).

## Os tipos (em inglês, como as lacunas): pessoa, rua ou endereço, lugar, telefone, hora, data, outro número, outro.
const KINDS := ["person", "street", "place", "phone", "time", "date", "number", "other"]

static var _mark := RegEx.create_from_string("\\[([a-z]+):([^\\]]+)\\]")

var word := ""      ## como foi dito ("Rua do Sol"), já no idioma em que foi ouvido
var kind := ""      ## um de `KINDS`
var night := 0      ## a noite em que foi ouvida
var minutes := 0.0  ## a hora do turno (`Main.minutes`)
var caller := ""    ## quem ligou (o nome original; `tr` para mostrar)
var number := ""    ## o número para onde ligou (`GameData.entry` dá o lugar)
var chosen := false ## marcada para repassar (na página de anotações)
var call: PhoneCall ## a conversa em que foi ouvida; só na noite dela (não se salva)


## Para salvar (`Progress.clues`).
func to_dict() -> Dictionary:
	return {"word": word, "kind": kind, "night": night, "minutes": minutes, "caller": caller, "number": number, "chosen": chosen}


static func from_dict(d: Dictionary) -> Clue:
	var k := Clue.new()
	for f in d:
		k.set(f, d[f])
	return k


## A fala `text` sem as marcas e onde fica cada palavra-chave nela: [texto, [[início, fim, tipo], ...]].
static func parse(text: String) -> Array:
	var plain := ""
	var spans := []
	var at := 0
	for m in _mark.search_all(text):
		plain += text.substr(at, m.get_start() - at)
		spans.append([plain.length(), plain.length() + m.get_string(2).length(), m.get_string(1)])
		plain += m.get_string(2)
		at = m.get_end()
	return [plain + text.substr(at), spans]
