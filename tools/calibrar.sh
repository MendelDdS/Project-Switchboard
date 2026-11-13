#!/bin/bash
# Calibração do conceito (README, "O conceito do turno e a demissão"): o robô do test_shift joga 5 sementes nas noites 1, 5, 9, 12
# e 15, como o atento (--human) e o desastrado (--clumsy), 5 turnos de cada vez (~2 min). Grava uma linha por turno
# em build/calibracao/<commit>.tsv (com "+" se há mudanças fora do commit) e imprime, por jogador, a eficiência
# (menor, mediana, maior) e quantas noites em cada conceito; com uma tabela anterior, as duas lado a lado:
#   tools/calibrar.sh [build/calibracao/<anterior>.tsv]
cd "$(dirname "$0")/.." || exit 1
G=/Applications/Godot.app/Contents/MacOS/Godot

if [ "$1" = --um ]; then   # um turno: perfil, noite, semente → a linha da tabela
	out=$("$G" --headless --fixed-fps 60 --path . tests/runner.tscn -- --test=shift --night="$3" --seed="$4" $([ "$2" = atento ] && echo --human || echo --clumsy) 2>&1)
	eff=$(sed -nE 's/^eficiência=([0-9]+)%.*/\1/p' <<<"$out")
	grade=$(sed -nE 's/^eficiência=.* conceito=([A-Z]+).*/\1/p' <<<"$out")
	lost=$(sed -nE 's/.* perdidas=([0-9]+).*/\1/p' <<<"$out")
	calls=$(sed -nE 's/.* ligações=([0-9]+).*/\1/p' <<<"$out")
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "${eff:-?}" "${grade:-FALHOU}" "${lost:-?}" "${calls:-?}"
	exit 0
fi

summary() {   # summary <tsv>: por jogador, eficiência menor/mediana/maior e as noites por conceito
	awk -F'\t' 'NR > 1 { e[$1] = e[$1] " " $4; g[$1, $5]++ }
	END {
		for (p in e) {
			n = split(substr(e[p], 2), v, " ")
			for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (v[j] + 0 < v[i] + 0) { t = v[i]; v[i] = v[j]; v[j] = t }
			printf "%-10s %3d%% %3d%% %3d%%   Ótimo %2d  Bom %2d  Regular %2d  Insuf. %2d  falhou %d\n", p, v[1], v[int((n + 1) / 2)], v[n],
				g[p, "GREAT"], g[p, "GOOD"], g[p, "FAIR"], g[p, "POOR"], g[p, "FALHOU"]
		}
	}' "$1" | sort
}

mkdir -p build/calibracao
name=$(git rev-parse --short HEAD)$([ -n "$(git status --porcelain -- scripts data)" ] && echo +)
tsv=build/calibracao/$name.tsv
printf 'jogador\tnoite\tsemente\teficiência\tconceito\tperdidas\tligações\n' >"$tsv"
for p in atento desastrado; do for n in 1 5 9 12 15; do for s in 1 2 3 4 5; do echo "$p $n $s"; done; done; done |
	xargs -P 5 -n 3 "$0" --um | sort -k1,1 -k2,2n -k3,3n >>"$tsv"
echo "jogador    menor mediana maior"
summary "$tsv"
if [ -n "$1" ]; then
	echo "--- antes ($1)"
	summary "$1"
fi
echo "(tabela: $tsv)"
