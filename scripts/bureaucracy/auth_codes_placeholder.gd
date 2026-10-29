extends "res://scripts/bureaucracy/auth_codes.gd"
## TEMPORÁRIO: o padrão definitivo dos códigos ainda não foi definido. Letra +2 e número +7 por noite, a partir de
## K-07 na noite 1 (K-07, M-14, O-21...); o `index` soma 1 aos dois.
## ponytail: as letras dão a volta em 13 noites e os pares só se repetem a cada 26; o jogo tem 15.


func code(night: int, index := 0) -> String:
	var letter := char(65 + posmod(10 + 2 * (night - 1) + index, 26))
	return "%s-%02d" % [letter, 7 * night + index]
