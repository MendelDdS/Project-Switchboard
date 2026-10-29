class_name Pace
extends Resource
## Um nível de ritmo do turno (GameContent.paces): quantas ligações sorteadas, com que intervalo e de que tipo.
## A primeira noite usa o nível 1; o nível sobe de uma noite para a outra (`Pace.next`) até o último, que é o limite.
## Do 1 ao 5 as ligações vêm cada vez mais seguidas; do 6 ao 9 (noites 7–15) vêm tantas quanto no 5 (`mean_gap`), só
## que mais juntas: picos mais frequentes, com a mesa mais calma entre eles (encurtar o intervalo do 5, 26–36 min,
## perdia 8 ligações por noite no robô `--human`). Medir: `-- --pace=N`.

## Nas noites até esta, o ritmo só sobe se a noite anterior não foi Insuficiente (`ShiftReport.grade`); depois dela, sobe sempre, até o limite. Na noite em que um setor é entregue
## (`GameData.SECTOR_NIGHTS`), ele não sobe: o operador aprende o bairro novo antes de as ligações apertarem.
const CONFIDENCE_NIGHTS := 3

## Minutos de jogo entre uma ligação sorteada e a próxima (o máximo é o maior silêncio possível).
@export var call_gap := Vector2(28.0, 42.0)
## Chance de a próxima ligação vir logo em seguida (`PEAK_GAP`): duas linhas juntas.
@export_range(0.0, 1.0) var peak_chance := 0.05
const PEAK_GAP := Vector2(2.0, 6.0)   ## minutos de jogo até a próxima, num pico
## Ligações tocando ou em andamento (ainda não conectadas) ao mesmo tempo; com tantas, a próxima espera.
@export_range(1, 10) var max_live := 3
## Duração (min de jogo) de uma conversa transferida: mais longa, prende os cabos de conexão por mais tempo (nos
## picos dos níveis altos chega a faltar cabo: esperar uma acabar ou cortar).
@export var talk_len := Vector2(34.0, 68.0)
## Quantas emergências e quantos trotes entre as ligações sorteadas.
@export var emergencies := Vector2i(1, 2)
@export var pranks := Vector2i(0, 2)


## Minutos de jogo, em média, de uma ligação sorteada para a próxima (com os picos).
func mean_gap() -> float:
	var mid := func(v: Vector2) -> float: return (v.x + v.y) / 2.0
	return lerpf(mid.call(call_gap), mid.call(PEAK_GAP), peak_chance)


## Nível da noite `night + 1`, depois de jogar a noite `night` no nível `level` com o conceito `grade`.
static func next(level: int, night: int, grade: ShiftReport.Grade) -> int:
	if night < 1:   # o treinamento não conta: a noite 1 é sempre no primeiro nível
		return 1
	var hold := night + 1 <= CONFIDENCE_NIGHTS and grade == ShiftReport.Grade.POOR   # ainda sem confiança: repete o ritmo
	hold = hold or night + 1 > 1 and night + 1 in GameData.SECTOR_NIGHTS.values()   # noite de bairro novo
	return clampi(level + (0 if hold else 1), 1, GameData.CONTENT.paces.size())


## Nível da noite `night` para quem não tropeçou (noite forçada com `--night=N`, sem progresso salvo).
static func expected(night: int) -> int:
	var level := 1
	for n in range(1, night):
		level = next(level, n, ShiftReport.Grade.GREAT)
	return level
