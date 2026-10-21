#!/bin/bash
# Regressão visual: as mesmas capturas no commit dado (padrão HEAD) e no que está no disco, comparadas pixel a pixel
# (`tools/diff_shots.gd`). Diz quais imagens mudaram e onde; sem nada mudado, sai com 0.
#   tools/visual.sh [commit]       (com tela: uma captura de cada vez, janela pequena no canto, ~7 s cada)
# As de antes saem de uma cópia do commit (git worktree em build/visual/base, com o .godot copiado: sem --import) e
# ficam guardadas pelo hash, em build/visual/<hash>: na mesma HEAD, só as de depois são refeitas.
# Com --still o relógio das animações para (`PixelArt.ms`) e, com a semente, tudo sai igual de uma captura para outra.
# ponytail: sem chuva no conjunto: nela ainda muda alguma coisa (o vidro molhado, uns pingos) que não vem do sorteio
# nem do relógio; achar a fonte antes de incluí-la. Commits anteriores ao relógio parado (20/10/2026) não servem de
# referência: a vista deles muda sozinha.
cd "$(dirname "$0")/.." || exit 1
G=/Applications/Godot.app/Contents/MacOS/Godot
base=$(git rev-parse --short "${1:-HEAD}") || exit 1

# nome | opções do tools/shot.gd
SET="sala_1830|--hour=18:30 --weather=clear
sala_2100|--hour=21:00 --weather=clear
sala_2330|--hour=23:30 --weather=clear
sala_neblina|--hour=21:00 --weather=fog
lista|--hour=21:00 --weather=clear --clues
despacho|--hour=21:00 --weather=clear --card --punch
calculografo|--hour=21:00 --weather=clear --toll --tool=calculografo
mesa|--hour=21:00 --weather=clear --listen --patch=312
hover|--hour=21:00 --weather=clear --hover=lista
intro|--hour=18:00 --weather=clear --screen=intro
relatorio|--hour=23:59 --weather=clear --screen=report --rating=fair
amanhecer|--night=15 --hour=05:30 --weather=clear"

capture() {   # capture <pasta do projeto> <pasta de saída>: o --out do shot.gd é relativo ao projeto em que roda
	rm -rf "$1/build/visual/tmp"
	while IFS='|' read -r name opts; do
		# shellcheck disable=SC2086
		(cd "$1" && "$G" --fixed-fps 60 --resolution 160x90 --position 0,0 --quit-after 1500 --path . tools/shot.tscn -- --night=2 --seed=1 \
			--wait=5 --still $opts --out="build/visual/tmp/$name.png" >/dev/null 2>&1)
	done <<<"$SET"
	rm -rf "$2"
	mv "$1/build/visual/tmp" "$2"
}

before="$PWD/build/visual/$base"
if [ ! -f "$before/amanhecer.png" ]; then
	wt="$PWD/build/visual/base"
	if [ -d "$wt" ]; then git -C "$wt" checkout -q --detach "$base"; else git worktree add -q --detach "$wt" "$base"; fi
	[ -d "$wt/.godot" ] || cp -R .godot "$wt/"
	echo "Capturando $base..."
	capture "$wt" "$before"
fi
after="$PWD/build/visual/disco"
echo "Capturando o que está no disco..."
capture "$PWD" "$after"
"$G" --headless --path . -s tools/diff_shots.gd -- "build/visual/$base" build/visual/disco 2>&1 | grep -v "^Godot Engine"
exit "${PIPESTATUS[0]}"
