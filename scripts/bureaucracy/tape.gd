extends RefCounted
## Uma fita da B4 (`Tapes`), tirada do compartimento: a conversa que gravou, as palavras-chave ouvidas dela e o
## destino (`fate`).

enum Fate { INSIDE, ON_DESK, DELIVERED, DISCARDED, LEFT }   ## no gravador, na mesa, entregue, descartada, esquecida no gravador

var slot := -1   ## o lugar do compartimento de onde saiu (a virgem devolvida volta para ele, se estiver vazio)
var call: PhoneCall   ## a conversa gravada (null: virgem)
var who := ""   ## quem foi gravado, como o supervisor diz (`Supervisor.who`)
var hour := ""   ## quando começou a gravar
var words: Array[String] = []   ## as palavras-chave ouvidas dela
var marked := false   ## uma conversa que as autoridades pediram gravada (`Tapes.mark_key`)
var value := 0   ## os pontos que valeu na entrega
var fate := Fate.INSIDE


## As palavras-chave para o registro de decisões ("nada" sem nenhuma).
func words_text() -> String:
	return ", ".join(words) if not words.is_empty() else "nada"
