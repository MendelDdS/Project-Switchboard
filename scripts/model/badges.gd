extends RefCounted
## Os broches: recompensas que o operador ganha pelas noites (salvas no `Progress`, `badges` e `tally`; somem com ele,
## na demissão e depois da última noite) e que ficam espetados numa almofada na prateleira da mesa (`scripts/ui/badges.gd`).
## Só mecânica, nada do roteiro. Conferidos no fim de cada noite (`award`); o treinamento não conta.

## Na ordem dos lugares da almofada (quatro atrás, quatro na frente): id -> [nome, descrição].
const ALL := {
	"primorosas": [T.Key.BADGE_PERFECT, T.Key.BADGE_PERFECT_DESC],
	"anjo": [T.Key.BADGE_ANGEL, T.Key.BADGE_ANGEL_DESC],
	"linha_direta": [T.Key.BADGE_DIRECT, T.Key.BADGE_DIRECT_DESC],
	"longa_distancia": [T.Key.BADGE_TRUNK, T.Key.BADGE_TRUNK_DESC],
	"faro": [T.Key.BADGE_PRANK, T.Key.BADGE_PRANK_DESC],
	"contas": [T.Key.BADGE_BOOKS, T.Key.BADGE_BOOKS_DESC],
	"rush": [T.Key.BADGE_RUSH, T.Key.BADGE_RUSH_DESC],
	"veterano": [T.Key.BADGE_VETERAN, T.Key.BADGE_VETERAN_DESC],
}
const PERFECT := 3        ## noites sem nenhuma advertência
const ANGEL := 10         ## emergências socorridas no estágio inicial
const DIRECT := 5         ## noites seguidas sem ninguém tocando até desistir
const TRUNK := 15         ## interurbanos completados
const PRANK := 5          ## trotes reconhecidos
const VETERAN := 10       ## noites trabalhadas


## Soma a noite `night` (no ritmo `pace`, com o relatório `r`) às contas de `p` e espeta os broches que ela completou;
## devolve os novos.
static func award(p: Progress, r: ShiftReport, night: int, pace: int) -> Array:
	if night <= 0:
		return []
	var t := p.tally
	var faults := r.faults.map(func(f: Dictionary): return f["id"])
	var credits := r.credits.map(func(c: Dictionary): return c["id"])
	t["perfect"] = t.get("perfect", 0) + int(faults.is_empty())
	for k in ["emergency_ok", "trunk", "prank"]:
		t[k] = t.get(k, 0) + credits.count(k)
	t["direct"] = 0 if "missed" in faults else t.get("direct", 0) + 1
	var done := {
		"primorosas": t["perfect"] >= PERFECT,
		"anjo": t["emergency_ok"] >= ANGEL,
		"linha_direta": t["direct"] >= DIRECT,
		"longa_distancia": t["trunk"] >= TRUNK,
		"faro": t["prank"] >= PRANK,
		"contas": "trunk" in credits and not faults.any(func(id: String): return id.begins_with("toll_") or id.begins_with("register_")),
		"rush": pace >= GameData.CONTENT.paces.size() and r.grade() <= ShiftReport.Grade.GOOD,
		"veterano": night >= VETERAN,
	}
	var new := []
	for id: String in ALL:
		if done[id] and not p.badges.has(id):
			p.badges[id] = night
			new.append(id)
	return new
