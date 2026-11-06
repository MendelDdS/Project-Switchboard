"""Prepara as gravações do ambiente (Freesound, todas CC0) para o jogo: audio/ambience/<id>.ogg.

Rodar (o uv traz o soundfile e o numpy; o ffmpeg daqui não grava Ogg Vorbis):
    uv run --no-project --with soundfile --with numpy python tools/ambiente/preparar.py
A fonte de cada som fica em build/ambiente/fontes/<código do Freesound>.<ext>: o original (wav, flac, aif), baixado à
mão com uma conta no Freesound, quando houver; senão a prévia de qualidade alta (ogg, ~180 kbps), baixada sozinha.
Cada som: o trecho [de, até] (s), o filtro do ffmpeg, o volume (a sonoridade, LUFS, dos sintetizados que eles
substituem, para o `Sfx.WEATHER_MIX` valer igual; o trovão pelo pico, como o sintetizado) e, no loop, o fim emendado
no começo (LOOP_FADE s), sem respiro ao repetir.
"""
import json, subprocess, sys, tempfile
from pathlib import Path
import numpy as np
import soundfile as sf

RAIZ = Path(__file__).resolve().parent.parent.parent
FONTES = RAIZ / "build" / "ambiente" / "fontes"
SAIDA = RAIZ / "audio" / "ambience"
LOOP_FADE = 3.0
# id no jogo: código do Freesound, de, até, filtro, alvo ("-16.9" LUFS ou "pico -1.0" dBFS), loop
SONS = {
	"rain": ("81819", 0.5, 48.5, "highpass=f=40", -16.9, True),        # silencyo: chuva na janela, sala com eco
	"storm": ("567108", 0.3, 38.5, "highpass=f=40", -16.9, True),      # TRP: vento e chuva na janela (o fim sumia: cortado)
	"breeze": ("557380", 3.0, 105.0, "highpass=f=50", -20.2, True),    # Tonmeister88: vento uivando perto da janela
	"crickets": ("522299", 0.5, 222.0, "highpass=f=900,lowpass=f=7000", -18.8, True),   # Defelozedd94: grilos (de fora: sem o grave, menos agudo)
	"thunder": ("572443", 1.0, 9.5, "highpass=f=25", "pico -1.0", False),     # TRP: trovão distante, quatro deles
	"thunder~1": ("572443", 9.5, 24.0, "highpass=f=25", "pico -1.0", False),
	"thunder~2": ("572443", 37.5, 46.5, "highpass=f=25", "pico -1.0", False),
	"thunder~3": ("572443", 46.5, 60.0, "highpass=f=25", "pico -1.0", False),
}
AUTORES = {"81819": "silencyo", "567108": "TRP", "557380": "Tonmeister88", "522299": "Defelozedd94", "572443": "TRP"}


def fonte(cod: str) -> Path:
	for ext in ("wav", "flac", "aif", "aiff", "ogg"):
		p = FONTES / f"{cod}.{ext}"
		if p.exists():
			return p
	FONTES.mkdir(parents=True, exist_ok=True)
	pag = subprocess.run(["curl", "-sL", "-A", "Mozilla/5.0", f"https://freesound.org/people/{AUTORES[cod]}/sounds/{cod}/"],
		capture_output=True, text=True, check=True).stdout
	url = pag.split('data-ogg="', 1)[1].split('"', 1)[0].replace("-lq.ogg", "-hq.ogg")
	p = FONTES / f"{cod}.ogg"
	subprocess.run(["curl", "-sL", "-A", "Mozilla/5.0", "-o", str(p), url], check=True)
	return p


def lufs(wav: Path) -> float:
	err = subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-i", str(wav), "-af", "ebur128", "-f", "null", "-"],
		capture_output=True, text=True).stderr
	return float(err.rsplit(" I:", 1)[1].split("LUFS", 1)[0])


def preparar(sid: str) -> None:
	cod, de, ate, filtro, alvo, loop = SONS[sid]
	with tempfile.TemporaryDirectory() as tmp:
		wav = Path(tmp) / "x.wav"
		subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-y", "-i", str(fonte(cod)), "-ss", str(de), "-to", str(ate),
			"-af", filtro, "-ar", "48000", "-ac", "2", str(wav)], check=True)
		a, sr = sf.read(wav, dtype="float32")
		if isinstance(alvo, str):   # pelo pico
			a *= 10 ** (float(alvo.split()[1]) / 20) / max(np.abs(a).max(), 1e-6)
		else:
			a *= 10 ** ((alvo - lufs(wav)) / 20)
	if loop:   # o fim emendado no começo, com a mesma potência (raiz), como o `SfxSynth._loopify`
		f = int(LOOP_FADE * sr)
		k = np.linspace(0.0, 1.0, f, endpoint=False, dtype="float32")[:, None]
		a[:f] = a[:f] * np.sqrt(k) + a[-f:] * np.sqrt(1.0 - k)
		a = a[:-f]
	else:   # o trovão: entra sem estalo e some no fim do trecho
		a[: int(0.02 * sr)] *= np.linspace(0, 1, int(0.02 * sr), dtype="float32")[:, None]
		a[-int(1.5 * sr):] *= np.linspace(1, 0, int(1.5 * sr), dtype="float32")[:, None]
	pico = np.abs(a).max()
	if pico > 0.97:   # (sem estourar: o volume pedido passou do teto)
		a *= 0.97 / pico
	SAIDA.mkdir(parents=True, exist_ok=True)
	with sf.SoundFile(SAIDA / f"{sid.replace('~', '_')}.ogg", "w", sr, 2, format="OGG", subtype="VORBIS") as o:
		for i in range(0, len(a), 4096):   # (em blocos: de uma vez, o libsndfile 1.2.2 cai no Vorbis com arquivo longo)
			o.write(a[i:i + 4096])
	print(f"{sid}: {cod}, {len(a) / sr:.1f} s, pico {20 * np.log10(np.abs(a).max()):.1f} dBFS")


for sid in sys.argv[1:] or SONS:
	preparar(sid)
