class_name MapGrid
extends RefCounted
## A grade do mapa da cidade (a mesma em cada folha) e os lugares marcados nela: o que o desenho (`CityMap`) e as falas
## de quem liga (`GameData.template_emergency`) usam em comum, sem depender da interface (os testes compilam sem o
## autoload `Sfx`).

const SHEETS := {3: Vector2(0, 0), 1: Vector2(600, 0), 2: Vector2(0, 440), 0: Vector2(600, 440)}
const SHEET_SECTOR := {0: 2, 1: 1, 2: 2, 3: 3}
const XS := [20.0, 110.0, 250.0, 390.0, 530.0, 580.0]   # grade de cada folha (as ruas ficam nos valores do meio)
const YS := [34.0, 90.0, 225.0, 360.0, 420.0]
## Lugares de cada folha, no quarteirão "coluna,linha" da grade (perto do endereço deles na lista).
## Cada um tem `<chave>_OF` ("do posto") para quem liga dizer onde é (`landmark_spots`).
const LM := {
	1: {"2,1": T.Key.MAP_SQUARE, "1,1": T.Key.MAP_CITY_HALL, "3,1": T.Key.MAP_POST_OFFICE, "2,0": T.Key.MAP_HOSPITAL,
		"1,2": T.Key.MAP_POLICE, "3,2": T.Key.MAP_FIRE_STATION, "4,1": T.Key.MAP_PHARMACY, "4,2": T.Key.MAP_BUS_STATION,
		"2,3": T.Key.MAP_BAKERY, "1,0": T.Key.MAP_NEWSPAPER},
	2: {"1,0": T.Key.MAP_CLINIC, "3,0": T.Key.MAP_SCHOOL, "2,1": T.Key.MAP_BARBER, "1,2": T.Key.MAP_GROCERY,
		"3,2": T.Key.MAP_WAREHOUSE, "4,3": T.Key.MAP_FARM},
	3: {"4,0": T.Key.MAP_SAWMILL, "3,0": T.Key.MAP_GARAGE, "0,1": T.Key.MAP_HOTEL, "2,1": T.Key.MAP_BAR,
		"3,1": T.Key.MAP_RADIO, "0,2": T.Key.MAP_CINEMA, "2,3": T.Key.MAP_GAS_STATION, "3,3": T.Key.MAP_FUNERAL,
		"0,3": T.Key.MAP_POOL_HALL, "1,0": T.Key.MAP_INN, "4,2": T.Key.MAP_TIRE_SHOP},
}


## Lugares do mapa ao lado de um trecho de rua, nos setores atendidos: [{"street": Street, "block": trecho, "lm": T.Key}].
## Só entra a rua em que o quarteirão do lugar fica inteiro ao lado de um único trecho (sem ambiguidade de qual
## trecho clicar): é o que quem liga pode dizer em vez do número ("Rua do Sol, perto do posto").
static func landmark_spots() -> Array:
	var out := []
	for sheet in LM:
		if not SHEET_SECTOR[sheet] in GameData.sectors:
			continue
		for key: String in LM[sheet]:
			var ci := int(key.get_slice(",", 0))
			var ri := int(key.get_slice(",", 1))
			var lo := Vector2(XS[ci] + 11.0, YS[ri] + 11.0)   # o quarteirão, sem a calçada
			var hi := Vector2(XS[ci + 1] - 11.0, YS[ri + 1] - 11.0)
			for st: Street in GameData.CONTENT.streets:
				var off := 0 if st.sector == sheet else (3 if st.continues == sheet else -1)
				var along := Vector2(lo.x, hi.x) if st.horizontal else Vector2(lo.y, hi.y)
				var side := [YS[ri], YS[ri + 1]] if st.horizontal else [XS[ci], XS[ci + 1]]
				if off < 0 or not st.pos in side:
					continue
				var start := 20.0 if st.horizontal else 34.0
				var seg := (560.0 if st.horizontal else 386.0) / 3.0
				var lb := floori((along.x - start) / seg)
				if lb == floori((along.y - start) / seg):
					out.append({"street": st, "block": lb + off, "lm": LM[sheet][key]})
	return out
