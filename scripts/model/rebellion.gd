extends RefCounted
## O fator sucesso da rebelião de Sebastião (`PLANO_ROTEIRO.md`): sai só dos marcadores do roteiro (`StoryFlags`), que
## as ligações e as fitas ligam (`StoryCall.if_*`, `if_delivered`), e da noite em que se está (o que Maria deixou de
## fazer só conta depois que a noite do pedido passou). Sem estado: o Main chama `sync` quando um marcador muda e
## ao carregar a noite, e as conclusões viram marcadores também (`DERIVED`), para o roteiro usar em `requires`.
##
## A conta, em pontos (`POINTS`): a emissora de TV (Dia 4) e a rádio (Dia 9) valem 2 cada; o que "cai pela metade"
## (fita das armas, do grupo C, do comandante; a denúncia; o hospital e a paróquia esquecidos) tira 2; o que "cai um
## pouco" (o hotel avisado no Dia 8, a fita do Dia 12 que não chegou a Sebastião) tira 1, e a fita entregue a ele
## soma 1; cada pedido das autoridades atendido nas noites 14 e 15 (`obedeceu_*`) é um vacilo e tira 1. Os Dias 2 e 3
## não tiram pontos por si: sem eles, Maria não fica sabendo da senha e a TV não vem.
## O nível (`level`): alto com 4 ou mais, médio com 2 ou 3, baixo abaixo disso. A carta do Dia 11 vem amiga só com o
## nível alto; a pedra da noite 14 vem com médio ou baixo; o golpe vence na noite 15 com médio ou alto à meia-noite
## (`won`). Na mesma hora sai o final (`final`): sucesso, vitória amarga, fracasso ou presa.

enum Level { LOW, MEDIUM, HIGH }
enum Final { SUCCESS, BITTER, FAILURE, PRISON }

## Os marcadores que o roteiro liga (os nomes que as ligações, o discador e as fitas usam).
const HOTEL := "senha_hotel_4"             ## Dia 4: ligou para o hotel às 20:30 e disse a senha
const DENOUNCED := "denunciou_bar_4"       ## Dia 4: denunciou o bar na delegacia
const TAPE_RADIO := "fita_radio_entregue"  ## Dia 7: entregou à polícia a fita da rádio...
const TAPE_GUNS := "fita_armas_entregue"   ## ...a das armas...
const TAPE_GROUP_C := "fita_grupo_c_entregue"   ## ...a do grupo C
const TAPE_GROUPS := "fita_grupos_entregue"     ## Dia 8: a fita do hotel com o local de cada grupo...
const TAPE_CHIEF := "fita_comandante_entregue"  ## ...a do comandante no armazém
const WARNED_HOTEL := "avisou_hotel_8"     ## Dia 8: avisou o hotel da escuta (nada passa, e o sucesso cai um pouco)
const HOSPITAL := "hospital_8"             ## Dia 8: deu o recado da ala 3C à Enfermeira Joana
const IGNORED := "cumpriu_9"               ## Dia 9: ignorou as ligações para a delegacia e a Alta Cúpula
const PARISH := "paroquia_10"              ## Dia 10: pediu abrigo à paróquia
const TAPE_SEBASTIAO := "fita_sebastiao_12"   ## Dia 12: entregou a Sebastião a fita das autoridades com a Alta Cúpula
const OBEYED := "obedeceu_"                ## Noites 14 e 15: um por pedido das autoridades atendido ("obedeceu_<id>")...
const DISOBEYED := "desobedeceu_"          ## ...e um por pedido cortado ou recusado ("desobedeceu_<id>"): no fracasso, presa

## As conclusões, ligadas e desligadas por `sync` (não se liga à mão).
const TV := "tv_conquistada"
const RADIO := "radio_conquistada"
const HOTEL_TAPED := "fita_hotel_entregue"   ## alguma fita do hotel (Dia 8) chegou à polícia: a batida da noite 13
const CHANCE := ["chance_baixa", "chance_media", "chance_alta"]   ## o nível agora, um ligado por vez (`Level`)
const WON := "golpe_venceu"   ## a conta da meia-noite da noite 15 (`Main._midnight`): amanhece...
const LOST := "golpe_falhou"  ## ...ou o turno acaba ali
const FINALS := ["final_sucesso", "final_amarga", "final_fracasso", "final_presa"]   ## o final (`Final`), ligado à meia-noite da 15
const COSTLY := [TAPE_GUNS, TAPE_GROUP_C, TAPE_GROUPS]   ## as fitas que custaram gente (Dias 7 e 8): a vitória amarga
const DERIVED := [TV, RADIO, HOTEL_TAPED, "chance_baixa", "chance_media", "chance_alta"]

const POINTS := {"tv": 2, "radio": 2, "half": -2, "little": -1, "sebastiao": 1, "obeyed": -1}
const HIGH_FROM := 4
const MEDIUM_FROM := 2


## A emissora de TV: ligou para o hotel com a senha e não denunciou o bar (conta do fim da noite 4 em diante).
static func tv(f: StoryFlags, night: int) -> bool:
	return night > 4 and f.has(HOTEL) and not f.has(DENOUNCED)


## A rádio: Maria cumpriu o pedido do Dia 9 e a polícia não recebeu nenhuma das fitas que a entregam (a da rádio, a
## do local dos grupos, ou as armas e o grupo C juntos com o hospital esquecido ou o hotel avisado).
static func radio(f: StoryFlags, night: int) -> bool:
	if night <= 9 or not f.has(IGNORED) or f.has(TAPE_RADIO) or f.has(TAPE_GROUPS):
		return false
	return not (f.has(TAPE_GUNS) and f.has(TAPE_GROUP_C) and (not f.has(HOSPITAL) or f.has(WARNED_HOTEL)))


static func points(f: StoryFlags, night: int) -> int:
	var p := 0
	if tv(f, night):
		p += POINTS["tv"]
	if radio(f, night):
		p += POINTS["radio"]
	for half in [TAPE_GUNS, TAPE_GROUP_C, TAPE_CHIEF, DENOUNCED]:
		if f.has(half):
			p += POINTS["half"]
	if night > 8 and not f.has(HOSPITAL):
		p += POINTS["half"]
	if night > 10 and not f.has(PARISH):
		p += POINTS["half"]
	if f.has(WARNED_HOTEL):
		p += POINTS["little"]
	if f.has(TAPE_SEBASTIAO):
		p += POINTS["sebastiao"]
	elif night > 12:
		p += POINTS["little"]
	for n in f.names():
		if n.begins_with(OBEYED):
			p += POINTS["obeyed"]
	return p


static func level(f: StoryFlags, night: int) -> Level:
	var p := points(f, night)
	return Level.HIGH if p >= HIGH_FROM else Level.MEDIUM if p >= MEDIUM_FROM else Level.LOW


## O golpe vence (a conta da meia-noite da noite 15): nível médio ou alto.
static func won(f: StoryFlags, night: int) -> bool:
	return level(f, night) != Level.LOW


## O final, à meia-noite da noite 15: com o golpe vencido, o sucesso, ou a vitória amarga se uma fita custou gente
## (`COSTLY`) ou a paróquia ficou esquecida; com o golpe falho, a presa se Maria cortou ou recusou mais pedidos das
## autoridades nas noites 14 e 15 do que atendeu (`DISOBEYED`; ficou do lado da rebelião no fim, e elas têm as
## gravações; um corte só, obedecendo o resto, não basta), senão o fracasso.
static func final(f: StoryFlags, night: int) -> Final:
	if won(f, night):
		return Final.BITTER if COSTLY.any(f.has) or not f.has(PARISH) else Final.SUCCESS
	var names := Array(f.names())
	var no := names.filter(func(n: String) -> bool: return n.begins_with(DISOBEYED)).size()
	return Final.PRISON if no > names.filter(func(n: String) -> bool: return n.begins_with(OBEYED)).size() else Final.FAILURE


## Liga as conclusões (`DERIVED`) conforme os marcadores agora; só mexe no que mudou.
static func sync(f: StoryFlags, night: int) -> void:
	var lv := level(f, night)
	var on := {TV: tv(f, night), RADIO: radio(f, night), HOTEL_TAPED: f.has(TAPE_GROUPS) or f.has(TAPE_CHIEF)}
	for i in CHANCE.size():
		on[CHANCE[i]] = i == lv
	for k: String in on:
		f.apply(k if on[k] else "!" + k)
