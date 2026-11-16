"""O rádio e a TV do vizinho, ouvidos pela parede (`Sfx.neighbors`): fala inventada com a cadência do português (o
pulso glotal e os formantes da voz das ligações, `SfxSynth._syllable`, aqui com consoantes, entonação e um timbre por
pessoa), vinhetas, músicas, filmes, palmas, torcida e quem está na sala de lá. Tudo sintetizado, nada gravado: audio/neighbors/<id>.ogg.

Rodar (o uv traz o soundfile, o numpy e o scipy; o ffmpeg daqui não grava Ogg Vorbis):
    uv run --no-project --with soundfile --with numpy --with scipy python tools/vizinhos/gerar.py
Com uma pasta no fim, grava nela também os wav para ouvir: <id>_parede (o do jogo) e <id>_aparelho (sem a parede).
Depois da pasta, os nomes dos sons a refazer (sem eles, todos: uns 5 min). O sorteio tem semente fixa, uma por som:
rodar de novo dá os mesmos. Mudou algo: ouça antes de trocar os do jogo.
"""
import sys
import numpy as np
from scipy.signal import lfilter, butter
from scipy.io import wavfile
import soundfile as sf
from pathlib import Path

SAIDA = Path(__file__).resolve().parent.parent.parent / "audio" / "neighbors"
LEVEL = 0.07   # o volume médio (RMS) de cada som gravado: o do jogo fica no `Sfx.VOL`

RATE = 22050
VOWEL = {"a": (780, 1250, 2600), "e": (480, 1850, 2550), "i": (310, 2250, 3000), "o": (500, 880, 2500), "u": (350, 720, 2400)}
VOWEL_W = {"a": 0.30, "e": 0.24, "o": 0.22, "i": 0.14, "u": 0.10}   # a frequência das vogais no português, por alto
BW = (90, 110, 170)
F4 = (3500, 250)
GLOTTIS = (0.4, 0.16)
rng = np.random.default_rng(7)


def resonator(x, f, bw):
    r = np.exp(-np.pi * bw / RATE)
    return lfilter([1.0 - r], [1.0, -2.0 * r * np.cos(2 * np.pi * f / RATE), r * r], x)


def filt(x, kind, f, order=2):
    b, a = butter(order, np.array(f) / (RATE / 2), kind)
    return lfilter(b, a, x)


def norm(x, peak=1.0):
    return x * (peak / max(1e-9, np.max(np.abs(x))))


def edges(x, sec=0.004):
    """As pontas do pedaço em rampa: o filtro deixa um resto que, cortado, estala."""
    n = min(int(sec * RATE), len(x) // 2)
    x = x.copy()
    x[:n] *= np.arange(n) / n
    x[-n:] *= np.arange(n)[::-1] / n
    return x


def vowel(f0, dur, vw, tract=1.0, nasal=False, breath=0.08):
    """Uma vogal: `f0` (Hz) no começo e no fim, `dur` s."""
    n = int(dur * RATE)
    f = np.linspace(f0[0], f0[1], n) * (1.0 + 0.012 * np.sin(2 * np.pi * 5.5 * np.arange(n) / RATE))
    ph = np.cumsum(f / RATE) % 1.0
    g = np.where(ph < GLOTTIS[0], 0.5 * (1 - np.cos(np.pi * ph / GLOTTIS[0])),
        np.where(ph < GLOTTIS[0] + GLOTTIS[1], np.cos(np.pi * (ph - GLOTTIS[0]) / (2 * GLOTTIS[1])), 0.0))
    src = np.diff(g, prepend=0.0)
    air = rng.uniform(-1, 1, n) * (0.4 + g)
    src = src / np.sqrt(np.mean(src ** 2) + 1e-12) * (1 - breath) + air / np.sqrt(np.mean(air ** 2)) * breath
    src *= np.sin(np.pi * np.arange(n) / n) ** 0.6
    fm = np.array(VOWEL[vw]) * tract
    y = resonator(src, fm[0] * (0.8 if nasal else 1.0), BW[0] * (2.0 if nasal else 1.0))
    y = resonator(resonator(resonator(y, fm[1], BW[1]), fm[2], BW[2]), F4[0] * tract, F4[1])
    if nasal:
        y = y + norm(resonator(src, 320, 100), 0.6 * np.max(np.abs(y)))
    return edges(norm(y), 0.006)


BLOCK = 22   # 1 ms: de quanto em quanto os formantes mudam (em 5 ms, a varredura rápida saía em degraus: um "twi" de laser)


def moving(x, t, sec):
    """A curva `x` alisada (média móvel de `sec` s): nenhuma mudança de volume ou de boca é um degrau."""
    n = max(1, int(sec * RATE))
    return np.convolve(np.pad(x, (n, n), mode="edge"), np.ones(n) / n, mode="same")[n:-n]


def glide(src, f, bw):
    """O formante que anda: o ressoador em blocos de 5 ms, levando o estado de um para o outro."""
    out = np.empty_like(src)
    zi = np.zeros(2)
    for k in range(0, len(src), BLOCK):
        fk = f[min(k + BLOCK // 2, len(f) - 1)]
        r = np.exp(-np.pi * bw / RATE)
        out[k:k + BLOCK], zi = lfilter([1.0 - r], [1.0, -2.0 * r * np.cos(2 * np.pi * fk / RATE), r * r], src[k:k + BLOCK], zi=zi)
    return out


# ---- as sílabas do português, por alto: "ataque|vogais|coda"; "~" na vogal: nasal. Ortografia de ouvido
# (x = ch, j = j e "di", lh, nh, rr = o r forte), com o "o" e o "e" do fim da palavra já reduzidos a "u" e "i".
def _syl(text):
    return [tuple(x.split("|")) for x in text.split()]


FUNC = _syl("|u| |a| j|i| k|i| |i| d|u| d|a| |e~i| |u~| pr|a| k|o~| s|i| p|u|r n|a| n|u| m|a|s |o|s |a|s")
BODY = _syl("p|a| k|a| m|a| t|a| s|a| f|a| v|a| l|a| r|a| b|a| d|a| g|a| p|e| t|e| m|e| s|e| l|e| r|e| v|e| d|e| k|e| "
    "p|i| x|i| m|i| s|i| t|i| v|i| j|i| p|o| k|o| m|o| t|o| s|o| g|o| r|o| b|o| d|o| n|o| f|o| p|u| t|u| k|u| m|u| "
    "s|u| n|e| p|e|r t|a|r k|o~| m|e~| t|e~| s|a~| k|a~| |i~| |e|s d|e|s m|a|s p|o|s k|o|s p|ai| k|ai| m|ai| d|ei| "
    "s|ei| r|ei| k|ou| t|ou| lh|a| nh|o| x|a| x|e| j|a| j|e| rr|a| rr|o| |a| |e| |o| tr|a| pr|o| br|a| gr|a| k|ua|")
END = _syl("d|a| d|u| x|i| j|i| s|i| r|a| r|u| n|a| n|u| m|a| m|u| s|a| lh|a| lh|u| nh|a| nh|u| k|a| k|u| v|a| v|u| "
    "t|a|s d|u|s m|u|s r|a~u| j|e~i| t|a| t|u| l|a| d|i| z|a| z|u| s|u|")   # palavras de tônica na penúltima
END_STRESS = _syl("s|a~u| z|a~u| d|o|r t|a|r m|e|r v|e|r n|au| p|eu| |a|r |o|r s|i~| b|e~i| t|e~i| l|a| f|e| v|o| "
    "d|ei| k|ou| m|eu| t|a~u| m|a~i| |e|s f|a|s")   # e na última
FILL = _syl("|e| |e| |a~| |e~|")
PLACE = {"p": "lab", "b": "lab", "m": "lab", "f": "lab", "v": "lab", "t": "alv", "d": "alv", "n": "alv", "s": "alv",
    "z": "alv", "l": "alv", "r": "alv", "k": "vel", "g": "vel", "rr": "vel", "x": "pal", "j": "pal", "nh": "pal", "lh": "pal"}
## Para onde os formantes (F1, F2, F3) apontam em cada lugar da boca: a vogal sai dali e volta para ali, e é essa
## dobra que diz qual consoante foi. A velar segue a vogal (`_locus`).
LOCUS = {"lab": (280, 900, 2300), "alv": (300, 1700, 2700), "pal": (280, 2300, 3000)}
## Cada consoante: quanto dura (s), a quanto cai o volume, e o chiado (a faixa e a força; "" nenhum).
## (Quedas rasas e lentas, a voz não parava nunca e a fala virava só vogal escorregando, "aueuieu"; fundas e lentas,
## a volta da vogal parecia a voz levantando. Então: a voz para de verdade no p, t, k, f, s, ch, e volta depressa.)
MANNER = {"p": (0.075, 0.02, "p"), "t": (0.07, 0.02, "t"), "k": (0.075, 0.02, "k"),
    "b": (0.065, 0.12, "p"), "d": (0.06, 0.12, "t"), "g": (0.065, 0.12, "k"),
    "m": (0.075, 0.55, ""), "n": (0.065, 0.55, ""), "nh": (0.08, 0.55, ""), "f": (0.085, 0.03, "f"),
    "s": (0.095, 0.03, "s"), "x": (0.095, 0.03, "x"), "v": (0.065, 0.18, "f"), "z": (0.07, 0.18, "s"), "j": (0.07, 0.18, "x"),
    "l": (0.06, 0.55, ""), "lh": (0.075, 0.5, ""), "r": (0.035, 0.04, ""), "rr": (0.08, 0.1, "f"), "": (0.012, 0.93, "")}
## Boca fechada com a voz soando: só o grave passa (o murmúrio pelo nariz no m, n, nh; a voz presa atrás do b, d, g).
## (Sem isso, toda consoante com voz era a vogal mais baixa e escorregando: soava tudo "l", "laioloia".)
MURMUR = ("m", "n", "nh", "b", "d", "g")
MURMUR_HZ = 400
BURST = 0.012   # a soltura do b, d, g: mais curta e mais fraca que a do p, t, k
## O chiado (s, ch, f) e o sopro curto da soltura do p, t, k: a faixa e a força.
HISS = {"s": ((3000, 5200), 0.06), "x": ((1900, 3300), 0.07), "f": ((1200, 4200), 0.035),
    "p": ((500, 1500), 0.05), "t": ((2200, 4000), 0.05), "k": ((1300, 2600), 0.07)}
RELEASE = 0.02


## O timbre de cada pessoa: a glote (quanto do ciclo abre, quanto leva para fechar: fechando depressa, a voz sai
## brilhante e empostada; devagar, suave), `tilt` (o agudo que a voz não tem, 0 a 1), `bw` (formantes estreitos: voz
## cheia, de locutor; largos: apagada), `jitter`/`shimmer` (a altura e a força tremendo de ciclo em ciclo) e
## `rough` (um pulso forte, um fraco: a rouquidão).
VOICES = {
    "empostado": dict(glottis=(0.34, 0.10), tilt=0.0, bw=0.78, jitter=0.004, shimmer=0.0, rough=0.0),
    "clara": dict(glottis=(0.42, 0.13), tilt=0.15, bw=0.9, jitter=0.005, shimmer=0.03, rough=0.0),
    "suave": dict(glottis=(0.56, 0.24), tilt=0.5, bw=1.3, jitter=0.007, shimmer=0.05, rough=0.0),
    "veludo": dict(glottis=(0.48, 0.20), tilt=0.38, bw=0.85, jitter=0.004, shimmer=0.02, rough=0.0),
    "animado": dict(glottis=(0.36, 0.11), tilt=0.05, bw=0.9, jitter=0.009, shimmer=0.05, rough=0.0),
    "grave": dict(glottis=(0.44, 0.16), tilt=0.25, bw=1.0, jitter=0.008, shimmer=0.06, rough=0.08),
    "idosa": dict(glottis=(0.46, 0.18), tilt=0.3, bw=1.1, jitter=0.02, shimmer=0.12, rough=0.14),
    "rouco": dict(glottis=(0.38, 0.14), tilt=0.12, bw=1.05, jitter=0.03, shimmer=0.18, rough=0.32),
}


## Como a frase acaba: para onde a altura vai da última tônica em diante (a faixa sorteada), o peso no sorteio e
## se a última tônica sobe antes (a ênfase). Duas frases seguidas nunca acabam igual (`speech`).
ENDINGS = {"afirma": ((0.7, 0.8), 0.3, False), "afirma leve": ((0.84, 0.93), 0.2, False), "suspensa": ((0.97, 1.04), 0.14, False),
    "continua": ((1.08, 1.18), 0.18, False), "pergunta": ((1.25, 1.42), 0.08, False), "enfase": ((0.68, 0.8), 0.1, True)}


REACH = np.array([0.8, 0.45, 0.45])   # o quanto do caminho até o lugar da consoante os formantes andam


def _locus(c, v):
    """Os formantes na consoante `c` ao lado da vogal `v`: a caminho do lugar dela, sem chegar (a boca não fecha num
    ponto só; indo até o fim, do "p" ao "i" o segundo formante varria 1.300 Hz e a sílaba soava "pui")."""
    if PLACE[c] == "vel":   # o k e o g: perto do céu da boca nas vogais da frente, atrás nas outras
        to = (280, 2300, 2900) if v in "ei" else (280, 1200, 2400)
    else:
        to = LOCUS[PLACE[c]]
    return np.array(VOWEL[v]) + REACH * (np.array(to) - np.array(VOWEL[v]))


def _tracks(tract):
    """As curvas de uma voz, pedaço a pedaço (`seg`): a altura, a força, os formantes, o chiado (`h`, com a força
    `hg`), a boca fechada (`m`) e o nariz (`z`). Viram som no `render`."""
    tr = dict(f0=[], amp=[], fm=[[], [], []], hiss={k: [] for k in HISS}, mur=[], nz=[])

    def seg(n, tone_v, a, f, h="", m=0.0, hg=1.0, z=0.0):
        if n <= 0:
            return
        tr["f0"].append(np.full(n, tone_v) if np.isscalar(tone_v) else tone_v)
        tr["amp"].append(np.full(n, a) if np.isscalar(a) else a)
        tr["mur"].append(np.full(n, m))
        tr["nz"].append(np.full(n, z))
        for q in range(3):
            tr["fm"][q].append(np.full(n, f[q] * tract))
        for k in HISS:
            tr["hiss"][k].append(np.full(n, hg if k == h else 0.0))
    return tr, seg


def _onset(seg, c, v, tone_v, loud):
    """A consoante `c` antes da vogal `v`."""
    d, dip, h = MANNER[c]
    at = _locus(c, v) if c else VOWEL[v]
    if c in ("p", "t", "k"):   # a boca fechada, em silêncio, e o sopro ao abrir
        seg(int((d - RELEASE) * RATE), tone_v, dip * loud, at)
        seg(int(RELEASE * RATE), tone_v, dip * loud, at, h)
    elif c in ("b", "d", "g"):   # a boca fechada com a voz presa, e a soltura curta
        seg(int((d - BURST) * RATE), tone_v, dip * loud, at, "", 1.0)
        seg(int(BURST * RATE), tone_v, dip * loud, at, h, 1.0, 0.5)
    else:
        seg(int(d * RATE), tone_v, dip * loud, at, h, 1.0 if c in MURMUR else 0.0)


def _word():
    """Uma palavra inventada: as sílabas dela e qual é a tônica."""
    n = int(rng.choice([1, 2, 3, 4], p=[0.14, 0.4, 0.34, 0.12]))
    pick = lambda pool: pool[int(rng.integers(len(pool)))]
    if n == 1:
        return [pick(END_STRESS)], 0
    oxy = rng.random() < 0.25
    return [pick(BODY) for _ in range(n - 1)] + [pick(END_STRESS if oxy else END)], n - 1 if oxy else n - 2


def lexicon(n):
    """As palavras de um programa (o nome do produto, o do jogador, o bordão): sorteadas uma vez e repetidas. Sem
    palavra que volta, a fala inventada não parece língua nenhuma."""
    out = []
    while len(out) < n:
        w = _word()
        if len(w[0]) in (2, 3):
            out.append(w)
    return out


NEUTRAL = np.array([500.0, 1500.0, 2500.0])   # a boca em descanso: para onde a vogal átona vai
## A vogal átona: (quanto vai para o meio da boca, quanto dura, a força) antes da tônica e depois dela.
WEAK = {False: (0.25, 0.8, 0.88), True: (0.42, 0.62, 0.74)}


def phrase(f0, tract, rate, lively, words, breath, voice="clara", ending="afirma", hesitate=0.0, tremor=0.0, lex=(), say=0.0, brand=0.0):
    """Uma frase numa voz só, contínua: a altura, o volume e os formantes são curvas no tempo. As vogais são os
    alvos dos formantes; cada consoante puxa os formantes para o lugar dela na boca (`LOCUS`) e baixa o volume
    (`MANNER`), sem estalo. Palavras de sílabas do português, com as palavrinhas átonas entre elas (`FUNC`).
    `lex`: as palavras do programa, cada palavra da frase é uma delas com a chance `say`; `brand`: a chance de a
    frase acabar na primeira delas (o nome do produto, o bordão)."""
    # a melodia da frase: afirmação (cai no fim), continuação (sobe um pouco: a frase seguinte emenda) ou pergunta
    close = float(rng.uniform(*ENDINGS[ending][0]))
    bend = rng.uniform(0.7, 2.0)   # a curva do fim: cedo ou só no finzinho
    stretch = rng.uniform(1.15, 1.9)   # o quanto a última sílaba se arrasta
    reg = rng.uniform(0.93, 1.1)   # cada frase num registro um pouco diferente
    sylls = []   # (sílaba, tônica, fim de palavra, palavrinha, tropeço, depois da tônica)
    count = int(rng.integers(words[0], words[1] + 1))
    for i in range(count):
        if words[1] > 1 and rng.random() < 0.55:
            sylls.append((FUNC[int(rng.integers(len(FUNC)))], False, True, True, "", False))
        if lex and i == count - 1 and rng.random() < brand:
            w, st = lex[0]
        elif lex and rng.random() < say:
            w, st = lex[int(rng.integers(len(lex)))]
        else:
            w, st = _word()
        r = rng.random()
        if r < hesitate:   # o "é..." arrastado de quem procura a palavra
            sylls.append((FILL[int(rng.integers(len(FILL)))], False, True, True, "fill", False))
        elif r < hesitate * 1.6:   # a palavra começada, largada e dita de novo
            sylls.append((w[0], False, True, False, "cut", False))
        sylls += [(sy, k == st, k == len(w) - 1, False, "", k > st) for k, sy in enumerate(w)]
    tr, seg = _tracks(tract)
    stressed = [j for j, x in enumerate(sylls) if x[1]]
    focus = int(rng.choice(stressed)) if stressed else -1   # a palavra que a frase destaca
    tail = stressed[-1] if stressed else len(sylls) - 1   # a última tônica: dali em diante a frase fecha
    if ENDINGS[ending][2]:
        focus = tail

    for j, ((onset, vows, coda), stress, word_end, func, odd, after) in enumerate(sylls):
        pos = j / max(1, len(sylls) - 1)
        last = j == len(sylls) - 1
        nasal = vows.endswith("~") or "~" in vows
        vows = vows.replace("~", "")
        base = f0 * reg * (1.0 + lively * 0.9 * (0.5 - pos))   # a frase começa alta e vai descendo
        arc = lively * (rng.uniform(0.45, 0.85) * (1.6 if j == focus else 1.0) if stress else rng.uniform(-0.2, 0.15))
        red, short, soft = (0.0, 1.5, 1.0) if stress or odd == "fill" else WEAK[after]
        loud = soft * (0.92 if nasal else 1.0)
        if odd == "fill":
            base, arc, loud = base * 0.93, -0.05, loud * 0.8
        for c in ([onset[0], onset[1:]] if len(onset) == 2 and onset not in MANNER else [onset]):   # ("tr", "pr": duas)
            _onset(seg, c, vows[0], base, loud)
        nv = int(rate * rng.uniform(0.85, 1.15) * short * (stretch if last else 1.0) * (rng.uniform(3.0, 5.0) if odd == "fill" else 1.0)
            * (1.25 if len(vows) > 1 else 1.0) * RATE)
        tone_v = base * (1.0 + arc * np.sin(np.pi * np.linspace(0.0, 1.0, nv) ** rng.uniform(0.6, 1.3)) ** 2)
        if j >= tail:
            span = len(sylls) - tail
            tone_v = tone_v * close ** (np.linspace((j - tail) / span, (j - tail + 1) / span, nv) ** bend)
        cut = int(nv * 0.6) if len(vows) > 1 else nv   # o ditongo: a boca vai de uma vogal à outra
        for k, v in enumerate(vows[:2]):
            a, b = (0, cut) if k == 0 else (cut, nv)
            f = np.array(VOWEL[v]) * (np.array([0.8, 1.0, 1.0]) if nasal else 1.0)
            seg(b - a, tone_v[a:b], loud, f + red * (NEUTRAL - f), z=1.0 if nasal else 0.0)
        end = float(tone_v[-1])
        if coda:
            d, dip, h = MANNER[{"r": "rr", "s": "s"}.get(coda, coda)]
            seg(int(d * 0.8 * RATE), end, dip * loud, _locus(coda if coda != "r" else "rr", vows[-1]), h)
        if odd:
            seg(int(rng.uniform(0.08, 0.26) * RATE), end, 0.0, VOWEL[vows[-1]])
        elif word_end and not last and rng.random() < 0.35:   # um respiro entre as palavras
            seg(int(rng.uniform(0.02, 0.05) * RATE), end, 0.3 * loud, VOWEL[vows[-1]])
    return render(tr, tract, breath, voice, tremor)


def render(tr, tract, breath, voice, tremor=0.0, wander=0.025):
    """As curvas do `_tracks` viram som na voz `voice`."""
    f0s = moving(np.concatenate(tr["f0"]), None, 0.05)
    amp = moving(np.concatenate(tr["amp"]), None, 0.018)
    fm, hiss = tr["fm"], tr["hiss"]
    n = len(f0s)
    t = np.arange(n) / RATE
    edge = np.minimum(1.0, t / 0.04) * np.minimum(1.0, (n - np.arange(n)) / (rng.uniform(0.07, 0.14) * RATE))   # as pontas da frase
    amp *= edge
    # a voz nunca fica parada numa nota: um passeio lento e irregular no lugar do tremor regular, que soava a máquina
    drift = moving(rng.normal(0.0, 1.0, n // 200 + 2).repeat(200)[:n], None, 0.25)
    vc = VOICES[voice]
    fast = lambda: moving(rng.normal(0.0, 1.0, n // 150 + 2).repeat(150)[:n], None, 0.004)   # de ciclo em ciclo
    f = f0s * (1.0 + wander * drift / (np.max(np.abs(drift)) + 1e-9)) * (1.0 + vc["jitter"] * fast())
    if tremor > 0.0:   # a voz embargada: treme mais para o fim da frase
        shake = tremor * (0.35 + 0.65 * t / t[-1]) * np.sin(2 * np.pi * rng.uniform(5.6, 6.8) * t + rng.uniform(0, 6.28))
        f = f * (1.0 + 0.035 * shake)
        amp = amp * (1.0 - 0.14 * tremor * (1.0 + shake / tremor))
    cyc = np.cumsum(f / RATE)
    ph = cyc % 1.0
    op, cl = vc["glottis"]
    g = np.where(ph < op, 0.5 * (1 - np.cos(np.pi * ph / op)), np.where(ph < op + cl, np.cos(np.pi * (ph - op) / (2 * cl)), 0.0))
    g = g * (1.0 - vc["rough"] * (np.floor(cyc) % 2)) * (1.0 + vc["shimmer"] * fast())   # (troca com a glote fechada: sem degrau)
    src = np.diff(g, prepend=0.0)
    if vc["tilt"] > 0.0:
        src = lfilter([1.0 - vc["tilt"]], [1.0, -vc["tilt"]], src)
    air = rng.uniform(-1, 1, n) * (0.4 + g)
    src = (src / np.sqrt(np.mean(src ** 2) + 1e-12) * (1 - breath) + air / np.sqrt(np.mean(air ** 2)) * breath) * amp
    y = src
    for q in range(3):
        y = glide(y, moving(np.concatenate(fm[q]), None, 0.028), BW[q] * vc["bw"])
    y = resonator(y, F4[0] * tract, F4[1])
    nz = moving(np.concatenate(tr["nz"]), None, 0.03)
    if nz.any():   # a vogal nasal ("ão", "em"): parte do som sai pelo nariz, um grave a mais e a boca mais apagada
        nose = resonator(src, 270 * tract, 110)
        y = y * (1.0 - 0.3 * nz) + nose * nz * 0.6 * np.sqrt(np.mean(y ** 2) / (np.mean(nose ** 2) + 1e-12))
    # nivelada: um formante em cima de um harmônico da voz deixa uma vogal bem mais forte que a vizinha
    # (medida sem as quedas das consoantes: com elas, a vogal depois do silêncio saía mais forte)
    z = y / (amp + 0.05)
    level = np.sqrt(moving(z * z, None, 0.12))
    level = np.maximum(level, 0.35 * np.median(level))   # (sem piso, o resto dos formantes no silêncio era levantado: um "twi")
    y = z / level ** 0.75 * amp
    m = moving(np.concatenate(tr["mur"]), None, 0.006)   # de boca fechada só o grave sai, e a troca é de uma vez
    y = y * (1.0 - m) + filt(y, "lowpass", MURMUR_HZ) * m * 1.6   # (é ela que diz "m", "n", "b")
    y = norm(y)
    for k, (band, gain) in HISS.items():   # o chiado do s, do ch, do f: fraco e sem agudo (forte, soava como estalo)
        y += filt(rng.uniform(-1, 1, n), "bandpass", band) * moving(np.concatenate(hiss[k]), None, 0.012 if k in "ptk" else 0.03) * gain * edge   # (sem as pontas, o chiado da última sílaba era cortado de uma vez)
    return y


def who(f0, tract, rate, lively, words, breath, voice, **more):
    """Uma pessoa: a voz dela e o jeito de falar (`endings`: o peso de cada fim de frase; `hesitate`; `tremor`,
    `whisper`: a chance da frase embargada e da sussurrada; `dyn`: o quanto uma frase sai mais baixa que a outra;
    `air`: a chance de puxar o ar antes da frase; `laughs`: a de rir depois dela; `lex`, `say`, `brand`: as palavras que voltam, ver `phrase`)."""
    return dict(f0=f0, tract=tract, rate=rate, lively=lively, words=words, breath=breath, voice=voice, **more)


def line(v, prev=""):
    """Uma frase de `v`, sem acabar como a anterior (`prev`). Devolve o som e como acabou."""
    weights = v.get("endings") or {k: x[1] for k, x in ENDINGS.items()}
    kinds = [k for k in weights if k != prev] or list(weights)
    w = np.array([weights[k] for k in kinds])
    end = kinds[int(rng.choice(len(kinds), p=w / w.sum()))]
    hush = rng.random() < v.get("whisper", 0.0)
    shake = v.get("tremor", 0.0) if rng.random() < 0.4 else 0.0
    y = phrase(v["f0"], v["tract"], v["rate"] * rng.uniform(0.88, 1.15), v["lively"] * (0.5 if hush else 1.0), v["words"],
        0.75 if hush else v["breath"], v["voice"], end, v.get("hesitate", 0.0), shake, v.get("lex", ()), v.get("say", 0.0), v.get("brand", 0.0))
    return y * (0.5 if hush else 1.0) * rng.uniform(1.0 - v.get("dyn", 0.0), 1.0), end


def inhale(out, at, gain=0.03):
    """O ar puxado antes da frase que começa em `at`."""
    n = int(rng.uniform(0.2, 0.36) * RATE)
    k = np.linspace(0.0, 1.0, n)
    put(out, norm(filt(rng.uniform(-1, 1, n), "bandpass", (400, 1700)) * np.sin(np.pi * k ** 1.3) ** 2), at - n / RATE - 0.05, gain)


def speech(sec, v, pause=(0.35, 0.9)):
    """`v` (`who`) falando por `sec` s, frase a frase."""
    out = np.zeros(int(sec * RATE))
    at = rng.uniform(0.2, 0.6)
    end = ""
    while at < sec - 1.5:
        y, end = line(v, end)
        put(out, y, at)
        gap = rng.uniform(*pause)
        at += len(y) / RATE + gap
        if rng.random() < v.get("laughs", 0.0):   # ri da própria piada
            put(out, laugh(v["f0"] * 1.15, v["tract"], int(rng.integers(3, 6))), at - gap + 0.05, 0.55)
            at += 0.7
        if gap > 0.4 and rng.random() < v.get("air", 0.3):
            inhale(out, at)
    return out


def lines(out, people, at, until, pause=(0.3, 0.8), gain=0.9, mic=None):
    """Uma conversa: `people` se revezam de `at` a `until` s. Devolve quando acabou."""
    k, end = int(rng.integers(len(people))), ""
    while at < until - 1.0:
        y, end = line(people[k % len(people)], end)
        put(out, mic(y) if mic else y, at, gain)
        at += len(y) / RATE + rng.uniform(*pause)
        k += 1
    return at


def hm(v, up=False):
    """O "hm" de quem escuta: de boca fechada, caindo (concorda) ou subindo (duvida)."""
    f = v["f0"] * rng.uniform(0.95, 1.1)
    return norm(filt(vowel((f, f * (1.25 if up else 0.8)), rng.uniform(0.28, 0.45), "u", v["tract"], True, 0.15), "lowpass", 450))


def sigh(v):
    """O suspiro: quase só ar, caindo."""
    y = vowel((v["f0"] * 1.15, v["f0"] * 0.8), rng.uniform(0.5, 0.8), "a", v["tract"], False, 0.85)
    return y * np.linspace(1.0, 0.2, len(y))


def sob(v):
    """O choro contido: o ar puxado aos trancos e um gemido curto depois de cada um."""
    out = np.zeros(int(1.4 * RATE))
    at = 0.0
    for _ in range(int(rng.integers(2, 4))):
        n = int(rng.uniform(0.07, 0.12) * RATE)
        put(out, norm(filt(rng.uniform(-1, 1, n), "bandpass", (500, 1900)) * np.hanning(n)), at, 0.5)
        f = v["f0"] * rng.uniform(1.35, 1.6)
        put(out, vowel((f, f * 0.85), rng.uniform(0.1, 0.18), "e", v["tract"], True, 0.4), at + 0.12, 0.7)
        at += rng.uniform(0.32, 0.42)
    return out


def chorus(word, people=9, f0=(110, 260)):
    """A plateia respondendo junta: a mesma palavra (do `lexicon`) em várias vozes, cada uma no seu tempo."""
    out = np.zeros(int(2.5 * RATE))
    for _ in range(people):
        f = rng.uniform(*f0)
        voice = ["clara", "grave", "animado", "suave"][int(rng.integers(4))]
        put(out, phrase(f, 0.95 + f / 900.0, rng.uniform(0.11, 0.13), 0.3, (1, 1), 0.1, voice, "enfase", lex=[word], brand=1.0),
            rng.uniform(0.0, 0.14), rng.uniform(0.6, 1.0))
    return norm(out)


def ooh(dur, vw="u", people=14, f0=(110, 280), fall=0.75):
    """A plateia ou a torcida numa vogal só, caindo: o "uuuh" do quase gol, o "aaah" do erro."""
    out = np.zeros(int((dur + 0.5) * RATE))
    for _ in range(people):
        f = rng.uniform(*f0)
        put(out, vowel((f * rng.uniform(1.0, 1.15), f * fall), dur * rng.uniform(0.75, 1.0), vw, 0.95 + f / 900.0, False, 0.2),
            rng.uniform(0.0, 0.3), rng.uniform(0.5, 1.0))
    return norm(out)


def phone(x):
    """Quem fala pelo telefone para o estúdio: sem grave, sem agudo e saturado."""
    x = filt(filt(x, "highpass", 380, 3), "lowpass", 2600, 3)
    return np.tanh(2.2 * x / (np.percentile(np.abs(x), 99.5) + 1e-9)) * 0.6


def hall(x):
    """O microfone do auditório: o eco comprido da sala cheia."""
    wet = x.copy()
    for d, g in ((0.061, 0.32), (0.097, 0.26), (0.149, 0.2), (0.223, 0.13), (0.311, 0.08)):
        k = int(d * RATE)
        wet[k:] += x[:-k] * g
    return wet


def tone(f, dur, kind="piano", attack_s=0.02, vib=0.0):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    ph = 2 * np.pi * f * t + vib * np.sin(2 * np.pi * 5.2 * t)
    struck = kind in ("piano", "bell", "guitar", "bass")
    if kind == "brass":   # o metal: o brilho abre com o sopro e cede; três músicos quase na mesma nota
        b = 0.45 + 0.45 * np.minimum(1.0, t / 0.07) - 0.15 * t / max(dur, 1e-3)
        x = sum(np.sin(ph * k * d) / k * b ** (k - 1) for k in range(1, 11) for d in (0.997, 1.0, 1.004))
    elif kind == "strings":
        x = sum(np.sin(ph * k * d) / k for k in range(1, 7) for d in (0.996, 1.0, 1.004))
    elif kind == "bell":   # o metalofone do reclame: parciais fora da série, cada um morrendo no seu tempo
        x = sum(np.sin(ph * r) * a * np.exp(-t * (3.0 + 2.5 * i)) for i, (r, a) in enumerate(((1, 1), (2.76, 0.5), (5.4, 0.25), (8.9, 0.12))))
    elif kind == "organ":   # o órgão elétrico: os registros somados e o tremor do alto-falante
        x = sum(np.sin(ph * k) * a for k, a in ((1, 1.0), (2, 0.7), (3, 0.5), (4, 0.3), (6, 0.2))) * (1.0 + 0.15 * np.sin(2 * np.pi * 6.5 * t))
    elif kind == "flute":   # a flauta (e o clarinete da comédia): quase um tom puro, com o sopro
        x = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.1 * filt(rng.uniform(-1, 1, n), "bandpass", (min(f, 3000.0), min(f * 3, 9000.0)))
    elif kind == "guitar":   # o violão: a corda dedilhada, morrendo depressa
        x = sum(np.sin(ph * k) / k * np.exp(-t * (2.0 + 1.4 * k)) for k in range(1, 7))
    elif kind == "bass":   # o contrabaixo: grave e seco
        x = sum(np.sin(ph * k) / k ** 1.5 * np.exp(-t * (2.5 + 1.0 * k)) for k in range(1, 6))
    else:   # o piano: a corda batida, os agudos somem primeiro
        x = sum(np.sin(ph * k * (1 + 0.0004 * k * k)) / k * np.exp(-t * (1.2 + 0.9 * k)) for k in range(1, 8))
    if struck:
        return x * np.minimum(1.0, t / 0.004) * np.minimum(1.0, (dur - t) / 0.05)
    return x * np.minimum(1.0, t / attack_s) * np.minimum(1.0, (dur - t) / max(0.03, min(0.25, dur * 0.4)))


def st(note):
    """"A4" -> semitons a partir do lá 4."""
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    return names[note[0]] + (1 if "#" in note else 0) - (1 if "b" in note[1:] else 0) + 12 * (int(note[-1]) - 4)


def fz(semi):
    return 440.0 * 2 ** (semi / 12)


def hz(note):
    """"A4" -> Hz."""
    return fz(st(note))


def put(out, x, at, gain=1.0):
    i0 = max(0, int(at * RATE))
    m = min(len(x), len(out) - i0)
    if m > 0:
        out[i0:i0 + m] += x[:m] * gain


def room(x):
    """O estúdio em volta da música: uns ecos curtos."""
    wet = x.copy()
    for d, g in ((0.031, 0.3), (0.047, 0.24), (0.071, 0.17), (0.113, 0.1)):
        k = int(d * RATE)
        wet[k:] += x[:-k] * g
    return wet


def slow(n, step, smooth):
    """Uma curva que passeia devagar entre 0 e 1."""
    k = int(step * RATE)
    x = moving(rng.normal(0.0, 1.0, n // k + 2).repeat(k)[:n], None, smooth)
    return (x - x.min()) / (x.max() - x.min() + 1e-9)


def drum(kind, f=98.0):
    """O bumbo, a caixa, o chimbal, o ganzá e o tímpano (este, na nota `f`)."""
    if kind == "kick":
        t = np.arange(int(0.2 * RATE)) / RATE
        return np.sin(2 * np.pi * np.cumsum(45 + 70 * np.exp(-t / 0.03)) / RATE) * np.exp(-t / 0.07)
    if kind == "snare":
        t = np.arange(int(0.16 * RATE)) / RATE
        return norm(filt(rng.uniform(-1, 1, len(t)), "bandpass", (900, 3200)) * np.exp(-t / 0.045) + 0.5 * np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.03))
    if kind == "hat":
        t = np.arange(int(0.05 * RATE)) / RATE
        return norm(filt(rng.uniform(-1, 1, len(t)), "highpass", 2600) * np.exp(-t / 0.012)) * 0.35
    if kind == "shaker":   # o ganzá, as maracas, o triângulo: areia
        t = np.arange(int(0.08 * RATE)) / RATE
        return norm(filt(rng.uniform(-1, 1, len(t)), "bandpass", (2200, 6000)) * np.sin(np.pi * t / t[-1]) ** 2) * 0.3
    t = np.arange(int(0.9 * RATE)) / RATE   # o tímpano: a pele afinada e a pancada
    return norm(np.sin(2 * np.pi * f * (1 + 0.03 * np.exp(-t / 0.05)) * t) * np.exp(-t / 0.3)
        + 0.4 * filt(rng.uniform(-1, 1, len(t)), "lowpass", 400) * np.exp(-t / 0.03))


def band(beat, parts, tail=1.0):
    """Um arranjo: `parts`, (instrumento, a pauta, a força). A pauta: "C5:1 E5+G5:0.5 -:2" (nota ou acorde e os
    tempos; "-" pausa; "|" só separa os compassos). Instrumentos: os do `tone`, os do `drum` e "voice" (a cantora)."""
    seqs = [[(x.split(":")[0], float(x.split(":")[1])) for x in text.replace("|", " ").split()] for _, text, _ in parts]
    out = np.zeros(int((max(sum(d for _, d in q) for q in seqs) * beat + tail) * RATE))
    for (kind, _, gain), q in zip(parts, seqs):
        at = 0.0
        if kind == "voice":   # a cantora canta as notas dela seguidas, depois das pausas do começo
            lead = sum(d for n, d in q if n == "-")
            put(out, sing([(hz(n), d) for n, d in q if n != "-"], beat), lead * beat, gain)
            continue
        for note, d in q:
            if note != "-":
                for nt in note.split("+"):
                    late = rng.uniform(0.0, 0.012)   # ninguém toca junto no mesmo milésimo
                    if kind in ("kick", "snare", "hat", "shaker", "timp"):
                        put(out, drum(kind, hz(nt) if kind == "timp" else 0.0), at * beat + late, gain * rng.uniform(0.8, 1.0))
                    else:
                        ring = {"bell": 1.6, "piano": 1.25}.get(kind, 0.95)
                        put(out, tone(hz(nt), d * beat * ring, kind, 0.12 if kind == "strings" else 0.02, 0.05 if kind == "strings" else 0.0),
                            at * beat + late, gain / len(note.split("+")) ** 0.6)
            at += d
    return norm(room(out))


def teletype(dur):
    """O telex batendo atrás do locutor: rajadas de batidas e a parada na volta do carro."""
    n = int(dur * RATE)
    hits = np.zeros(n)
    at = 0.0
    while at < dur - 0.1:
        for _ in range(int(rng.integers(8, 30))):
            if at >= dur - 0.1:
                break
            hits[int(at * RATE)] = rng.uniform(0.5, 1.0)
            at += rng.uniform(0.07, 0.1)
        at += rng.uniform(0.2, 0.6)
    m = int(0.012 * RATE)
    key = filt(rng.uniform(-1, 1, m) * np.exp(-np.arange(m) / (m * 0.2)), "bandpass", (1300, 3200))
    return norm(np.convolve(hits, key)[:n]) * np.minimum(1.0, np.arange(n) / (0.5 * RATE)) * np.minimum(1.0, np.arange(n)[::-1] / (0.5 * RATE))


## As vinhetas: (o tempo, s; as partes).
THEMES = {
    "news": (0.28, [   # tímpanos, metais em fanfarra, cordas e o baixo
        ("timp", "G2:0.5 G2:0.5 C3:1 -:2 | G2:0.5 G2:0.5 C3:1 -:2 | C3:1 -:3 | G2:0.5 G2:0.5 G2:0.5 G2:0.5 C3:4", 0.55),
        ("brass", "G4:0.5 G4:0.5 C5:1 E5:2 | G4:0.5 G4:0.5 D5:1 F5:2 | E5:1 D5:1 C5:1 D5:1 | E5:0.5 F5:0.5 G5:1 C5+E5+G5+C6:4", 0.9),
        ("strings", "C4+E4+G4:4 | B3+D4+G4:4 | A3+C4+E4:2 G3+B3+D4:2 | C4+E4+G4:6", 0.45),
        ("piano", "C2:4 | G2:4 | A2:2 G2:2 | C2:6", 0.6)]),
    "news_end": (0.28, [("timp", "G2:0.5 G2:0.5 C3:3", 0.5), ("brass", "G4:0.5 B4:0.5 C5+E5+G5:3", 0.9), ("strings", "C4+E4+G4:4", 0.4)]),
    "show": (0.2, [   # metais, piano, baixo andando e bateria
        ("brass", "G4:1 C5:1 E5:1 G5:2 E5:1 G5:2 | A5:1 G5:1 E5:1 C5:2 D5:1 E5:2 | G4:1 C5:1 E5:1 G5:2 A5:1 B5:2 | C6:6 -:2", 0.9),
        ("piano", "C3:2 E3:2 G3:2 A3:2 | F3:2 A3:2 G3:2 B2:2 | C3:2 E3:2 G3:2 A3:2 | C3:6 -:2", 0.7),
        ("piano", "-:1 C4+E4+G4:2 C4+E4+G4:2 C4+E4+G4:3 | -:1 F4+A4+C5:2 F4+A4+C5:1 G4+B4+D5:2 G4+B4+D5:2 | -:1 C4+E4+G4:2 C4+E4+G4:2 C4+E4+G4:3 | C4+E4+G4+C5:6 -:2", 0.45),
        ("kick", "x:4 x:4 | x:4 x:4 | x:4 x:4 | x:2 x:2 x:4", 0.7),
        ("snare", "-:2 x:4 x:2 | -:2 x:4 x:2 | -:2 x:4 x:2 | -:2 x:1 x:1 x:0.5 x:0.5 x:3", 0.45),
        ("hat", " ".join(["x:1"] * 30) + " -:2", 0.3)]),
    "show_sting": (0.2, [("brass", "C5+E5+G5:1 C5+E5+G5:1 C6:4", 0.9), ("kick", "x:1 x:1 x:4", 0.6), ("snare", "x:1 x:1 x:4", 0.4), ("piano", "C3:1 C3:1 C3:4", 0.6)]),
    "ad_1": (0.24, [   # metalofone, piano no contratempo, baixo e a cantora no refrão
        ("bell", "C5:1 E5:1 G5:1 E5:1 F5:1 D5:1 G5:2 | E5:1 G5:1 C6:1 G5:1 A5:1 F5:1 G5:2 | C5+E5+G5:4", 0.8),
        ("piano", "C3:2 C3:2 G2:2 G2:2 | C3:2 E3:2 F3:2 G3:2 | C3:4", 0.6),
        ("piano", "-:1 C4+E4+G4:1 -:1 C4+E4+G4:1 -:1 B3+D4+G4:1 -:1 B3+D4+G4:1 | -:1 C4+E4+G4:1 -:1 C4+E4+G4:1 -:1 F4+A4+C5:1 -:1 G4+B4+D5:1 | C4+E4+G4:4", 0.4),
        ("hat", "-:8 " + " ".join(["x:1"] * 8) + " -:4", 0.3),
        ("voice", "-:8 E4:1 G4:1 C5:1 G4:1 A4:1 F4:1 G4:2 C5:4", 0.75)]),
    "ad_2": (0.3, [   # um reclame sério, em valsa: cordas, piano e baixo
        ("strings", "A4:2 C5:1 F5:3 | E5:2 D5:1 C5:3 | A4:2 C5:1 D5:2 E5:1 | F5:6", 0.8),
        ("piano", "F2:3 F2:3 | C3:3 C3:3 | F2:3 G2:3 | F2:6", 0.6),
        ("piano", "-:1 A3+C4+F4:1 A3+C4+F4:1 -:1 A3+C4+F4:1 A3+C4+F4:1 | -:1 G3+C4+E4:1 G3+C4+E4:1 -:1 G3+C4+E4:1 G3+C4+E4:1 | -:1 A3+C4+F4:1 A3+C4+F4:1 -:1 G3+B3+D4:1 G3+B3+D4:1 | A3+C4+F4:6", 0.4)]),
    "ad_3": (0.24, [   # metalofone, metais respondendo e a cantora
        ("bell", "G5:1 E5:1 C5:2 A5:1 F5:1 D5:2 | G5:1 B5:1 C6:6", 0.8),
        ("brass", "-:3 C4+E4:1 -:3 D4+F4:1 | -:2 C4+E4+G4:6", 0.5),
        ("piano", "C3:4 F3:4 | G3:2 C3:6", 0.6),
        ("kick", "x:2 x:2 x:2 x:2 | x:2 x:6", 0.5),
        ("voice", "-:8 G4:1 B4:1 C5:6", 0.75)]),
    "station": (0.3, [("bell", "E5:2 C5:2 G4:2 C5:4", 0.8), ("piano", "C3:6 C3:4", 0.4)]),   # o sinal da emissora
    "flash": (0.16, [   # o plantão: tímpano batendo e os metais na mesma nota
        ("timp", "D3:1 D3:1 D3:1 D3:1 D3:1 D3:1 D3:2 | D3:1 D3:1 D3:1 D3:1 A2:4 | D3:6", 0.55),
        ("brass", "D5:1 D5:1 D5:2 D5:1 D5:1 D5:2 | F5:1 F5:1 F5:2 A5:4 | D5+F5+A5:6", 0.9),
        ("strings", "D4+F4+A4:8 | D4+F4+A4:8 | D4+F4+A4+D5:6", 0.4)]),
    "soap_sting": (0.3, [("strings", "E3+G3+Bb3+C#4:7", 0.8), ("timp", "E2:7", 0.6), ("piano", "E2:7", 0.6)]),   # o susto do fim do capítulo
    "ad_4": (0.22, [   # uma marchinha: metais, caixa e a cantora
        ("brass", "G4:1 C5:1 C5:1 E5:1 D5:1 C5:1 D5:2 | E5:1 G5:1 G5:1 E5:1 D5:1 B4:1 C5:2 | C5+E5+G5:4", 0.9),
        ("kick", "x:2 x:2 x:2 x:2 | x:2 x:2 x:2 x:2 | x:4", 0.6),
        ("snare", "-:1 x:2 x:2 x:2 x:1 | -:1 x:2 x:2 x:1 x:1 x:1 | x:4", 0.35),
        ("piano", "C3:2 G2:2 C3:2 G2:2 | C3:2 G2:2 G2:2 C3:2 | C3:4", 0.6),
        ("voice", "-:8 E4:1 G4:1 G4:1 E4:1 D4:1 B3:1 C4:2 | C4:4", 0.75)]),
    "ad_5": (0.34, [   # uma canção de ninar: metalofone, flauta e violão
        ("bell", "E5:1 G5:1 C6:1 | B5:2 G5:1 | A5:1 F5:1 D5:1 | E5:3 | C5+E5:3", 0.8),
        ("flute", "-:6 | C5:2 D5:1 | E5:3 | C5:3", 0.5),
        ("guitar", "C3:1 G3:1 E4:1 | G2:1 G3:1 D4:1 | F2:1 A3:1 D4:1 | C3:1 G3:1 E4:1 | C3:3", 0.6)]),
    "ad_6": (0.26, [   # um reclame moderno: violão, baixo, ganzá e a cantora
        ("guitar", "C3+E3+G3+B3:1.5 C3+E3+G3+B3:1.5 C3+E3+G3+B3:1 | D3+F3+A3+C4:1.5 D3+F3+A3+C4:1.5 G3+B3+D4+F4:1 | C3+E3+G3+B3:4", 0.7),
        ("bass", "C2:3 G2:1 | D2:3 G2:1 | C2:4", 0.7),
        ("shaker", " ".join(["x:0.5"] * 16) + " -:4", 0.5),
        ("voice", "E4:1.5 G4:1.5 B4:1 | A4:1.5 F4:1.5 D4:1 | E4:4", 0.75)]),
    "calouro": (0.3, [   # a caloura e o pianista do programa
        ("piano", "C3:2 G3:2 A2:2 E3:2 | F2:2 C3:2 G2:2 G3:2 | C3:2 G3:2 A2:2 E3:2 | F2:2 G2:2 C3:4", 0.5),
        ("piano", "-:1 E4+G4:1 -:1 E4+G4:1 -:1 C4+E4:1 -:1 C4+E4:1 | -:1 A3+C4:1 -:1 A3+C4:1 -:1 B3+D4:1 -:1 B3+D4:1 | "
            "-:1 E4+G4:1 -:1 E4+G4:1 -:1 C4+E4:1 -:1 C4+E4:1 | -:1 A3+C4:1 -:1 B3+D4:1 C4+E4+G4:4", 0.3),
        ("voice", "-:4 E4:1 G4:1 C5:1 B4:1 | A4:2 C5:1 A4:1 G4:2 B4:2 | C5:1 E5:1 D5:1 C5:1 A4:2 G4:2 | A4:1 C5:1 B4:1 D5:1 C5:4", 0.8)]),
    "adventure": (0.3, [   # o tema do herói: metais em fanfarra sobre o galope
        ("brass", "G4:1 C5:2 E5:1 G5:3 E5:1 | A5:2 G5:1 E5:2 C5:1 D5:2 | G4:1 C5:2 E5:1 G5:3 A5:1 | G5:2 E5:1 D5:2 B4:1 C5:4", 0.9),
        ("strings", "C4+E4+G4:8 | F4+A4+C5:4 G4+B4+D5:4 | C4+E4+G4:8 | G3+B3+D4:6 C4+E4+G4:4", 0.4),
        ("piano", "C2:8 | F2:4 G2:4 | C2:8 | G2:6 C2:4", 0.6)]),
    "soap": (0.33, [   # a abertura da novela: o piano por cima das cordas
        ("piano", "E5:2 D5:1 C5:3 | A4:2 B4:1 C5:3 | E5:2 D5:1 C5:2 B4:1 | A4:6", 0.8),
        ("piano", "A2:3 E3:3 | F2:3 C3:3 | D3:3 E3:3 | A2:6", 0.5),
        ("strings", "A3+C4+E4:6 | F3+A3+C4:6 | D3+F3+A3:3 E3+G#3+B3:3 | A3+C4+E4:6", 0.5)]),
}


def theme(name):
    return band(*THEMES[name])


def whistle():
    n = int(rng.uniform(0.25, 0.6) * RATE)
    f = np.linspace(rng.uniform(1700, 2100), rng.uniform(2300, 2900), n) * (1 + 0.02 * np.sin(2 * np.pi * 14 * np.arange(n) / RATE))
    return np.sin(2 * np.pi * np.cumsum(f / RATE)) * np.hanning(n)


def applause(dur, people=45, cheer=True):
    """Palmas de gente: cada um bate no seu ritmo, com a sua mão (o timbre) e para na sua hora; uns assobios."""
    n = int(dur * RATE)
    x = np.zeros(n)
    m = int(0.02 * RATE)
    for _ in range(people):
        rate = rng.uniform(2.8, 5.2)
        times = rng.uniform(0.0, 0.5) + np.cumsum(rng.uniform(0.85, 1.15, int(dur * rate) + 2) / rate)
        idx = (times[times < dur * rng.uniform(0.5, 1.0)] * RATE).astype(int)
        idx = idx[idx < n - 1]
        hits = np.zeros(n)
        hits[idx] = rng.uniform(0.6, 1.0, len(idx))
        fc = rng.uniform(900, 2500)
        hand = filt(rng.uniform(-1, 1, m) * np.exp(-np.arange(m) / (m * 0.2)), "bandpass", (fc * 0.6, fc * 1.5))
        x += np.convolve(hits, hand)[:n] * rng.uniform(0.4, 1.0)
    if cheer:
        for _ in range(int(dur / 1.6)):
            put(x, whistle(), rng.uniform(0.2, dur * 0.7), 0.9)
    return norm(x * np.minimum(1.0, np.arange(n) / (0.25 * RATE)))


def crowd(dur):
    """A torcida: faixas de vozerio, cada uma crescendo e cedendo na sua hora, assobios e uma corneta."""
    n = int(dur * RATE)
    x = np.zeros(n)
    for band, g in (((220, 500), 1.0), ((400, 800), 0.9), ((650, 1200), 0.7), ((1000, 1700), 0.4), ((1500, 2400), 0.22)):
        x += filt(rng.uniform(-1, 1, n), "bandpass", band) * (0.3 + 0.7 * slow(n, 0.5, 0.8)) * g
    x = norm(x)
    for _ in range(int(dur / 5)):
        put(x, whistle(), rng.uniform(0.0, dur - 1.0), 0.12)
    for _ in range(int(dur / 9)):
        put(x, tone(rng.uniform(220, 300), rng.uniform(0.3, 0.7), "brass", 0.05), rng.uniform(0.0, dur - 1.0), 0.03)
    return norm(x)


def street(dur):
    """A rua atrás da repórter: o ronco da cidade e os carros passando."""
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    x = norm(filt(rng.uniform(-1, 1, n), "lowpass", 320)) * 0.5
    for _ in range(max(2, int(dur / 4))):
        x += norm(filt(rng.uniform(-1, 1, n), "bandpass", (300, 1500))) * np.exp(-((t - rng.uniform(1.0, dur - 1.0)) / rng.uniform(0.5, 1.0)) ** 2) * 0.6
    return norm(x) * np.minimum(1.0, t / 0.4) * np.minimum(1.0, (dur - t) / 0.4)


SUNG = ["l", "n", "m", "r", "d", "t", "k", "s", "b", "v", ""]   # as consoantes de quem canta


def sing(notes, beat, tract=1.12, voice="suave", breath=0.1, sylls=None, hold=1.0):
    """Quem canta, sem palavras: uma sílaba por nota (`sylls`, (consoante, vogal), para o refrão voltar com as mesmas;
    sem elas, "la", "na", "ra" sorteados), a nota presa, o vibrato chegando depois que a nota assenta, o ar puxado
    a cada quatro notas. `notes`: (Hz, tempos), 0 Hz é pausa; `hold`: quanto da nota soa (menos de 1: destacado)."""
    tr, seg = _tracks(tract)
    last = next(f for f, _ in notes if f > 0)
    for i, (f, beats) in enumerate(notes):
        total = int(beats * beat * RATE)
        if f <= 0:
            seg(total, last, 0.0, VOWEL["a"])
            continue
        last = f
        c, v = sylls[i] if sylls else ("lnmrd"[int(rng.integers(5))], "aaoe"[int(rng.integers(4))])
        before = sum(len(x) for x in tr["amp"])
        _onset(seg, c, v, f, 1.0)
        gap = int(0.16 * RATE) if i % 4 == 3 and beats * beat > 0.5 else 0   # onde respira (numa nota que dê tempo)
        n = max(0, total - (sum(len(x) for x in tr["amp"]) - before) - gap)
        on = int(n * hold)
        if on > 1:
            tt = np.arange(on) / RATE
            vib = 0.02 * np.clip((tt - 0.22) / 0.3, 0.0, 1.0) * np.sin(2 * np.pi * rng.uniform(5.3, 5.9) * tt)
            seg(on, f * (1.0 + vib), 0.8 + 0.2 * np.clip(np.sin(np.pi * tt / tt[-1]), 0.0, 1.0) ** 0.7, VOWEL[v])
        seg(n - max(on, 0) + gap if on > 1 else n + gap, f, 0.0, VOWEL[v])
    return render(tr, tract, breath, voice, 0.0, 0.006)


def waltz(sec, bpm=92):
    """Uma valsa lenta em lá menor: o piano no baixo e nos acordes, as cordas na melodia."""
    beat = 60.0 / bpm
    out = np.zeros(int(sec * RATE))
    chords = [("A2", "A3+C4+E4"), ("D3", "A3+D4+F4"), ("E2", "G#3+B3+E4"), ("A2", "A3+C4+E4"),
              ("F2", "A3+C4+F4"), ("D3", "A3+D4+F4"), ("E2", "G#3+B3+D4"), ("A2", "A3+C4+E4")]
    tune = ["E5 2", "D5 1", "C5 2", "A4 1", "B4 2", "C5 1", "A4 3", "A5 2", "G5 1", "F5 2", "D5 1", "E5 2", "G#4 1", "A4 3"]
    at = 0.0
    bar = 0
    while at < sec - 3 * beat:
        bass, ch = chords[bar % len(chords)]
        put(out, tone(hz(bass), beat * 1.6, "piano"), at, 0.6)
        for k in (1, 2):
            for nt in ch.split("+"):   # (a mão do pianista nunca cai inteira no mesmo instante)
                put(out, tone(hz(nt), beat * 0.8, "piano"), at + k * beat + rng.uniform(0.0, 0.02), 0.2 * rng.uniform(0.8, 1.0))
        at += 3 * beat
        bar += 1
    at = 0.0
    i = 0
    while at < sec - 3 * beat:   # as cordas apresentam a melodia e depois ficam atrás da cantora
        note, d = tune[i % len(tune)].split()
        put(out, tone(hz(note), int(d) * beat * 0.97, "strings", 0.12, 0.06), at, 0.2 if i < len(tune) else 0.07)
        at += int(d) * beat
        i += 1
    turn = sum(int(x.split()[1]) for x in tune) * beat
    if sec > turn + 6 * beat:   # a cantora entra na segunda volta, uma oitava abaixo das cordas
        song = [(hz(x.split()[0]) / 2, int(x.split()[1])) for x in tune]
        put(out, sing([x for x in song if True], beat), turn, 0.5)
    return norm(room(out))


def pad(sec, chords, each):
    out = np.zeros(int(sec * RATE))
    for i, ch in enumerate(chords):
        for nt in ch.split("+"):
            put(out, tone(hz(nt), each * 1.1, "strings", 1.2, 0.04), i * each, 0.3)
    return norm(room(out))


# ---------------------------------------------------------------- a banda do rádio e a música dos filmes
QUAL = {"M": (0, 4, 7), "m": (0, 3, 7), "7": (0, 4, 7, 10), "m7": (0, 3, 7, 10), "M7": (0, 4, 7, 11)}   # os acordes
SCALES = {"major": (0, 2, 4, 5, 7, 9, 11), "minor": (0, 2, 3, 5, 7, 8, 10), "dorian": (0, 2, 3, 5, 7, 9, 10), "mixo": (0, 2, 4, 5, 7, 9, 10)}


def groove(sec, bpm, chords, drums=(), bass=None, comp=(), pad=None, stabs=None):
    """A levada de uma música, compasso a compasso, em 16 passos (semicolcheias). `chords`: (a nota do baixo, o
    acorde, `QUAL`), um por compasso, em roda. Os desenhos são textos de 16 letras: "x" toca, "o" toca fraco, "."
    cala. `drums`: (peça, desenho ou desenhos que se revezam, força); `bass`: (instrumento, desenho com o grau do
    acorde em cada passo: 1, 3, 5, 7, 8, força); `comp`: (instrumento, desenho, força, oitavas acima do baixo, se
    arpeja); `pad`: o acorde preso o compasso todo, (instrumento, força, oitavas); `stabs`: a resposta dos metais,
    (instrumento, desenho, força, de quantos em quantos compassos, oitavas)."""
    step = 60.0 / bpm / 4
    bars = int(sec / (16 * step))
    out = np.zeros(int(sec * RATE))
    for bar in range(bars):
        root, q = chords[bar % len(chords)]
        r, iv = st(root), QUAL[q]
        t0 = bar * 16 * step
        for kind, pats, gain in drums:
            pat = pats if isinstance(pats, str) else pats[bar % len(pats)]
            for i, ch in enumerate(pat):
                if ch != ".":   # (ninguém toca junto no mesmo milésimo)
                    put(out, drum(kind), t0 + i * step + rng.uniform(0.0, 0.008), gain * (1.0 if ch == "x" else 0.45) * rng.uniform(0.85, 1.0))
        if bass:
            kind, pat, gain = bass
            hits = [i for i, ch in enumerate(pat) if ch != "."]
            for a, i in enumerate(hits):
                deg = {"1": 0, "3": iv[1], "5": iv[2], "7": iv[3] if len(iv) > 3 else 10, "8": 12}[pat[i]]
                ln = min((hits[a + 1] if a + 1 < len(hits) else 16) - i, 6)
                put(out, tone(fz(r + deg), ln * step * 0.95, kind), t0 + i * step, gain)
        for kind, pat, gain, octv, arp in comp:
            hits = [i for i, ch in enumerate(pat) if ch != "."]
            for a, i in enumerate(hits):
                ln = min((hits[a + 1] if a + 1 < len(hits) else 16) - i, 8)
                for sm in ([iv[a % len(iv)]] if arp else iv):
                    put(out, tone(fz(r + sm + 12 * octv), ln * step * (1.0 if pat[i] == "x" else 0.5), kind),
                        t0 + i * step + rng.uniform(0.0, 0.012), gain / (1 if arp else len(iv)) ** 0.6)
        if pad:
            kind, gain, octv = pad
            for sm in iv[:3]:
                put(out, tone(fz(r + sm + 12 * octv), 16 * step * 0.98, kind, 0.15, 0.05), t0, gain / 3 ** 0.6)
        if stabs and bar % stabs[3] == stabs[3] - 1:
            kind, pat, gain, _, octv = stabs
            for i, ch in enumerate(pat):
                if ch != ".":
                    for sm in iv[-3:]:
                        put(out, tone(fz(r + sm + 12 * octv), 1.7 * step, kind), t0 + i * step, gain / 3 ** 0.6)
    return out, bars


def melody(phrases, chords, key, scale, rhythms, center, first=0, plan="AABA"):
    """Uma melodia sorteada, em frases de dois compassos (`plan`: a frase A volta, com as mesmas sílabas, como um
    refrão). `rhythms`: desenhos de 32 passos ("x" começa a nota, "-" segura, "." cala). As notas andam por graus da
    escala e caem numa nota do acorde nos tempos e nas notas compridas. Devolve as notas, (semitom ou None, passos),
    e a sílaba de cada uma."""
    k0 = st(key + "4") % 12
    lad = [x for x in range(-40, 30) if (x - k0) % 12 in SCALES[scale]]
    home = min(range(len(lad)), key=lambda i: abs(lad[i] - center))
    motifs, out, syl = {}, [], []
    for ph in range(phrases):
        name = plan[ph % len(plan)]
        if name not in motifs:
            r = rhythms[int(rng.integers(len(rhythms)))]
            n = r.count("x")
            motifs[name] = (r, rng.choice([-2, -1, -1, 0, 1, 1, 2], n),
                [(SUNG[int(rng.integers(len(SUNG)))], "aaeoiu"[int(rng.integers(6))]) for _ in range(n)])
        r, moves, words = motifs[name]
        p, k, i = home, 0, 0
        while i < 32:
            j = i + 1
            if r[i] != "x":
                while j < 32 and r[j] != "x":
                    j += 1
                out.append((None, j - i))
                syl.append(None)
            else:
                while j < 32 and r[j] == "-":
                    j += 1
                root, q = chords[(first + ph * 2 + i // 16) % len(chords)]
                mv = int(moves[k])
                if not 0 <= p + mv < len(lad) or abs(lad[p + mv] - center) > 9:
                    mv = -mv
                p += mv
                if i % 4 == 0 or j - i >= 4 or k == 0:   # no tempo ou comprida: uma nota do acorde
                    tones = {x % 12 for x in QUAL[q]}
                    p = next((p + o for o in (0, 1, -1, 2, -2, 3, -3) if 0 <= p + o < len(lad) and (lad[p + o] - st(root)) % 12 in tones), p)
                out.append((lad[p], j - i))
                syl.append(words[k])
                k += 1
            i = j
    return out, syl


def song(cfg, sec):
    """Uma música: a levada (`groove`), e a melodia sorteada na voz de quem canta ou num instrumento."""
    step = 60.0 / cfg["bpm"] / 4
    intro = cfg.get("intro", 2)
    out, bars = groove(sec, cfg["bpm"], cfg["chords"], cfg.get("drums", ()), cfg.get("bass"), cfg.get("comp", ()), cfg.get("pad"), cfg.get("stabs"))
    tune, syl = melody((bars - intro) // 2, cfg["chords"], cfg["key"], cfg["scale"], cfg["rhythms"], st(cfg["center"]), intro)
    if cfg["lead"] == "voice":
        voice, tract, breath = cfg["voice"]
        notes = [(fz(x) if x is not None else 0.0, d) for x, d in tune]
        put(out, sing(notes, step, tract, voice, breath, syl, cfg.get("hold", 1.0)), intro * 16 * step, cfg.get("gain", 0.55))
    else:
        at = intro * 16 * step
        for x, d in tune:
            if x is not None:
                put(out, tone(fz(x), d * step * cfg.get("hold", 0.95), cfg["lead"], 0.03, 0.04), at, cfg.get("gain", 0.3))
            at += d * step
    return norm(room(out))


## As músicas do rádio (todas inventadas: a levada do gênero e uma melodia sorteada). "hit": as agitadas, com o
## locutor falando por cima da introdução; "calm": as calmas, com o locutor no fim. `dj`: a voz do locutor (`who`).
## `gain`: a força de quem canta sobre a banda (medida: com 0,55 a voz das agitadas ficava a um terço da banda).
SONGS = {
    "hit_1": dict(gain=1.3, bpm=104, key="E", scale="dorian", center="B3", lead="voice", voice=("veludo", 0.97, 0.08), hold=0.85, intro=2,   # soul, com metais
        chords=[("E2", "m7"), ("E2", "m7"), ("A2", "7"), ("A2", "7"), ("E2", "m7"), ("E2", "m7"), ("C3", "M7"), ("B2", "7")],
        drums=[("kick", ["x..x......x.x...", "x..x..x...x....."], 0.6), ("snare", "....x.......x...", 0.4), ("hat", "x.xox.xox.xox.xo", 0.22)],
        bass=("bass", "1..1..78..1.5.7.", 0.6), comp=[("organ", "..x...x....x..x.", 0.2, 2, False)], stabs=("brass", "x.x...x.........", 0.3, 2, 2),
        rhythms=["x.x..x.x-...x...x.x..x--........", "..x.x.x-..x.x---x--.x--.........", "x---x---x.x.x---x-------........"],
        dj=(146, 1.03, 0.1, 0.4, (3, 6), 0.07, "animado")),
    "hit_2": dict(gain=1.3, bpm=100, key="D", scale="major", center="A4", lead="voice", voice=("clara", 1.16, 0.08), hold=0.9, intro=2,   # samba com piano
        chords=[("D2", "M7"), ("B2", "7"), ("E2", "m7"), ("A2", "7"), ("F#2", "m7"), ("B2", "7"), ("E2", "m7"), ("A2", "7")],
        drums=[("kick", "x...x..xx...x..x", 0.45), ("shaker", "xoxoxoxoxoxoxoxo", 0.2), ("snare", "o.o.oo.o.o.o.oo.", 0.25)],
        bass=("bass", "1..5..1.1..5..1.", 0.55), comp=[("piano", "x..x..x...x.x...", 0.25, 2, False)],
        rhythms=["x.xx.x.x-.x.x---x.xx.x.x--......", "x-x-.x.xx-..x.x-x---x---x---....", "..x.x.xx-.x.x.x-x-----..x.x-...."],
        dj=(210, 1.18, 0.1, 0.38, (3, 6), 0.08, "animado")),
    "hit_3": dict(gain=1.3, bpm=138, key="G", scale="major", center="D4", lead="voice", voice=("animado", 1.03, 0.08), hold=0.9, intro=4,   # iê-iê-iê
        chords=[("G2", "M"), ("G2", "M"), ("E2", "m"), ("E2", "m"), ("C3", "M"), ("C3", "M"), ("D3", "7"), ("D3", "7")],
        drums=[("kick", "x.......x.x.....", 0.6), ("snare", "....x.......x...", 0.45), ("hat", "x.x.x.x.x.x.x.x.", 0.2)],
        bass=("bass", "1.1.1.1.1.1.5.5.", 0.5), comp=[("guitar", "x.x.x.x.x.x.x.x.", 0.2, 2, False)], pad=("organ", 0.1, 2),
        rhythms=["x.x.x-x-x---....x.x.x-x-x-------", "x---x.x.x-x-....x---x---x-------", "..x.x.x.x---x---x.x.x-x-x---...."],
        dj=(132, 1.02, 0.1, 0.42, (3, 6), 0.07, "animado")),
    "hit_4": dict(gain=1.3, bpm=108, key="A", scale="mixo", center="A3", lead="voice", voice=("grave", 0.99, 0.1), hold=0.9, intro=2,   # baião, com sanfona
        chords=[("A2", "7"), ("A2", "7"), ("D3", "M"), ("A2", "7"), ("G2", "M"), ("A2", "7"), ("G2", "M"), ("A2", "7")],
        drums=[("kick", "x..x..x.x..x..x.", 0.55), ("shaker", "xoxxxoxxxoxxxoxx", 0.2)],
        bass=("bass", "1..5..8.1..5..8.", 0.5), comp=[("strings", "..x...x...x...x.", 0.2, 2, False)],
        rhythms=["x.xx.xx-x.x-....x.xx.xx-x---....", "x-.xx-.xx-x-x-..x.x.x-x-x-------"],
        dj=(120, 1.0, 0.105, 0.38, (3, 6), 0.08, "rouco")),
    "calm_2": dict(bpm=70, key="C", scale="major", center="G4", lead="voice", voice=("suave", 1.14, 0.2), intro=1,   # bossa, com violão
        chords=[("C2", "M7"), ("C2", "M7"), ("D2", "m7"), ("G2", "7"), ("E2", "m7"), ("A2", "7"), ("D2", "m7"), ("G2", "7")],
        drums=[("shaker", "x.x.x.x.x.x.x.x.", 0.1), ("snare", "..o..o....o..o..", 0.2)],
        bass=("bass", "1.......5.......", 0.5), comp=[("guitar", "x..x..x...x..x..", 0.3, 2, False)],
        rhythms=["..x-x-.x--x-....x---..x-x-------", "x--x--x-....x--x--x---------....", "....x-x-x---x-..x-----x---------"],
        dj=(196, 1.15, 0.13, 0.22, (3, 5), 0.14, "suave")),
    "calm_3": dict(gain=0.75, bpm=80, key="D", scale="minor", center="A3", lead="voice", voice=("veludo", 0.96, 0.1), intro=1,   # bolero, com cordas
        chords=[("D2", "m"), ("G2", "m"), ("A2", "7"), ("D2", "m"), ("D2", "m"), ("G2", "m"), ("A2", "7"), ("D2", "m")],
        drums=[("shaker", "x.xxx.x.x.x.x.x.", 0.12)],
        bass=("bass", "1.....5.1...5...", 0.5), comp=[("guitar", "x.x.x.x.x.x.x.x.", 0.25, 2, True)], pad=("strings", 0.14, 2),
        rhythms=["x-------x---x---x-----------....", "x---x---x-------x---x-x---------", "....x---x---x---x-------x-------"],
        dj=(104, 0.96, 0.14, 0.2, (3, 5), 0.1, "veludo")),
}


# ---------------------------------------------------------------- os programas (40 s cada)
SEC = 40.0
## Como cada tipo de programa fecha as frases.
NEWS = {"afirma": 0.5, "afirma leve": 0.2, "continua": 0.25, "suspensa": 0.05}
REPORT = {"continua": 0.4, "afirma leve": 0.3, "afirma": 0.2, "suspensa": 0.1}
DRAMA = {"suspensa": 0.28, "pergunta": 0.24, "afirma leve": 0.2, "afirma": 0.13, "enfase": 0.15}
SHOW = {"enfase": 0.35, "pergunta": 0.15, "continua": 0.3, "afirma": 0.2}
MATCH = {"continua": 0.6, "suspensa": 0.2, "enfase": 0.2}
AD = {"enfase": 0.4, "afirma": 0.3, "continua": 0.3}
RADIO = {"afirma leve": 0.4, "suspensa": 0.3, "afirma": 0.3}


FIGHT = {"enfase": 0.4, "pergunta": 0.3, "afirma": 0.2, "suspensa": 0.1}
TENSE = {"enfase": 0.5, "pergunta": 0.25, "continua": 0.25}


def noticiario():
    """O jornal da noite: o locutor, a repórter na rua e o locutor de volta."""
    out = np.zeros(int(SEC * RATE))
    names = lexicon(3)   # os nomes do dia, na boca do locutor e da repórter
    anchor = who(122, 1.03, 0.12, 0.18, (3, 6), 0.05, "empostado", endings=NEWS, air=0.25, lex=names, say=0.2)
    put(out, theme("news"), 0.3, 0.55)
    put(out, speech(17.5, anchor, (0.3, 0.6)), 6.2)
    put(out, teletype(18.0), 6.0, 0.06)
    reporter = who(226, 1.2, 0.118, 0.22, (3, 5), 0.1, "clara", endings=REPORT, hesitate=0.1, air=0.5, lex=names, say=0.2)
    put(out, filt(speech(10.5, reporter, (0.3, 0.6)), "highpass", 330), 24.0, 0.9)   # o microfone de rua
    put(out, street(11.0), 23.8, 0.22)
    put(out, speech(3.6, anchor, (0.3, 0.5)), 34.6)
    put(out, teletype(3.6), 34.6, 0.06)
    put(out, theme("news_end"), 38.0, 0.5)
    return out


def plantao():
    """O plantão: a locutora com pressa, o telex alto e um homem falando pelo telefone, de longe."""
    out = np.zeros(int(SEC * RATE))
    names = lexicon(3)
    anchor = who(202, 1.17, 0.108, 0.2, (4, 7), 0.05, "empostado", endings=NEWS, air=0.3, lex=names, say=0.25)
    put(out, theme("flash"), 0.3, 0.55)
    put(out, speech(11.0, anchor, (0.25, 0.5)), 4.4)
    put(out, teletype(34.0), 4.2, 0.09)
    caller = who(112, 0.97, 0.125, 0.2, (3, 6), 0.1, "grave", endings=REPORT, hesitate=0.18, air=0.5, lex=names, say=0.2)
    n = int(12.6 * RATE)
    put(out, phone(speech(12.0, caller, (0.3, 0.7))) + filt(rng.uniform(-1, 1, int(12.0 * RATE)), "bandpass", (400, 2400)) * 0.03, 16.0, 0.8)
    put(out, speech(8.6, anchor, (0.25, 0.5)), 28.6)
    put(out, theme("news_end"), 37.6, 0.5)
    return out


def jornal_dupla():
    """O jornal de dois locutores, uma notícia de cada, a previsão do tempo com um fundo calmo e o boa-noite."""
    out = np.zeros(int(SEC * RATE))
    names = lexicon(3)
    ele = who(112, 1.0, 0.118, 0.18, (3, 6), 0.05, "empostado", endings=NEWS, air=0.25, lex=names, say=0.2)
    ela = who(198, 1.16, 0.115, 0.2, (3, 6), 0.06, "clara", endings=NEWS, air=0.3, lex=names, say=0.2)
    put(out, theme("news_end"), 0.3, 0.55)
    at, k, end = 3.4, 0, ""
    while at < 24.0:
        for _ in range(int(rng.integers(1, 3))):
            y, end = line((ele, ela)[k % 2], end)
            put(out, y, at)
            at += len(y) / RATE + rng.uniform(0.25, 0.5)
        put(out, tone(hz("G5"), 0.5, "bell"), at, 0.18)   # o sinal entre uma notícia e outra
        at += 0.7
        k += 1
    put(out, pad(36.0 - at, ["C4+E4+G4", "A3+C4+E4", "F3+A3+C4", "G3+B3+D4"], (36.0 - at) / 4), at, 0.14)
    put(out, speech(36.2 - at, dict(ela, lively=0.26, rate=0.13, endings=RADIO), (0.35, 0.7)), at + 0.3)
    bye = lexicon(1)
    for i, v in enumerate((ele, ela)):
        put(out, phrase(v["f0"], v["tract"], v["rate"], v["lively"], (1, 1), v["breath"], v["voice"], "afirma", lex=bye, brand=1.0), 36.5 + 0.95 * i)
    put(out, theme("news_end"), 38.3, 0.5)
    return out


def novela(ep=1):
    """Um capítulo, em conversa: a resposta curta, a fala que atropela a do outro, o silêncio comprido antes de
    responder, quem ouve reagindo ("hm", um suspiro), o choro, e o susto do fim. `ep`: 1, o casal; 2, a briga da mãe
    com a filha, que acaba na porta batida; 3, a mãe e a criança, e depois ele chega."""
    out = np.zeros(int(SEC * RATE))
    names = dict(lex=lexicon(2), say=0.25)   # os nomes de quem está na cena e de quem eles falam
    moca = who(176, 1.1, 0.16, 0.3, (2, 4), 0.16, "suave", endings=DRAMA, hesitate=0.12, tremor=0.8, whisper=0.15, dyn=0.35, **names)
    gala = who(92, 0.92, 0.17, 0.24, (2, 4), 0.12, "grave", endings=DRAMA, hesitate=0.1, tremor=0.35, whisper=0.08, dyn=0.3, **names)
    if ep == 1:
        chords = ["A3+C4+E4", "D3+F3+A3", "E3+G#3+B3", "A3+C4+E4", "F3+A3+C4", "E3+G#3+B3+D4"]
        scenes = [(8.4, 36.0, (moca, gala), 0.18, 0.18)]
    elif ep == 2:
        chords = ["D3+F3+A3", "D3+F3+G#3+B3", "C3+E3+G3", "D3+F3+G#3+B3", "E3+G#3+B3", "D3+F3+A3"]
        senhora = who(162, 1.07, 0.15, 0.36, (2, 5), 0.1, "idosa", endings=FIGHT, hesitate=0.05, tremor=0.3, dyn=0.2, **names)
        filha = who(218, 1.16, 0.125, 0.4, (2, 5), 0.12, "clara", endings=FIGHT, tremor=0.7, dyn=0.25, **names)
        scenes = [(8.4, 33.2, (senhora, filha), 0.45, 0.06)]
        put(out, room(knock(70, 0.3, (50, 500))), 33.6, 0.8)   # a porta batida
        put(out, sob(filha), 34.3, 0.45)
    else:
        chords = ["F3+A3+C4", "D3+F3+A3", "A#3+D4+F4", "C4+E4+G4", "D3+F3+A3", "E3+G3+A#3+C#4"]
        crianca = who(305, 1.4, 0.13, 0.42, (1, 3), 0.12, "clara", endings={"pergunta": 0.5, "continua": 0.3, "afirma leve": 0.2}, hesitate=0.15, **names)
        scenes = [(8.4, 20.5, (dict(moca, tremor=0.2, whisper=0.0), crianca), 0.1, 0.1), (23.6, 36.0, (gala, dict(moca, whisper=0.5)), 0.1, 0.4)]
        put(out, room(steps(3)), 20.6, 0.3)   # ele chegando
        for k in range(3):
            put(out, room(knock(160, 0.06, (150, 900))), 22.3 + 0.22 * k, 0.4)
    put(out, pad(SEC, chords, SEC / 6), 0.0, 0.16)
    put(out, theme("soap"), 0.2, 0.5)
    for start, stop, pair, rush, wait in scenes:
        at, k, end = start, 0, ""
        while at < stop - 2.0:
            v, other = pair[k % 2], pair[(k + 1) % 2]
            short = k > 0 and rng.random() < 0.25
            for _ in range(1 if short else int(rng.integers(1, 3))):
                y, end = line(dict(v, words=(1, 1)) if short else v, end)
                put(out, y, at, 0.9)
                at += len(y) / RATE + rng.uniform(0.4, 0.9)
            if v.get("tremor", 0.0) > 0.5 and rng.random() < 0.1:
                put(out, sob(v), at - 0.3, 0.4)
                at += 1.0
            r = rng.random()
            gap = -rng.uniform(0.5, 0.9) if r < rush else (rng.uniform(1.4, 2.4) if r < rush + wait else rng.uniform(0.0, 0.6))
            at += gap
            if gap > 1.0 and rng.random() < 0.6:   # quem ouviu reage antes de responder
                put(out, hm(other, rng.random() < 0.4) if rng.random() < 0.6 else sigh(other), at - 0.8, 0.3)
            elif gap > 0.0 and rng.random() < 0.55:
                inhale(out, at, 0.035)
            k += 1
    put(out, theme("soap_sting"), 36.6, 0.5)
    return out


HOST = dict(endings=SHOW, hesitate=0.08, dyn=0.2, air=0.4, laughs=0.3)


def auditorio():
    """O programa de auditório: o apresentador no microfone da sala, o bordão, a plateia respondendo e as palmas."""
    out = np.zeros(int(SEC * RATE))
    host = who(138, 1.02, 0.105, 0.42, (3, 6), 0.07, "animado", lex=lexicon(2), say=0.15, brand=0.3, **HOST)
    put(out, theme("show"), 0.2, 0.5)
    put(out, applause(4.5), 5.2, 0.45)
    for at, d in [(8.6, 7.0), (19.4, 5.2), (29.2, 5.4)]:
        put(out, hall(speech(d, host, (0.2, 0.45))), at)
    put(out, hall(chorus(host["lex"][0])), 24.6, 0.55)   # ele puxa o bordão e a plateia devolve
    for at, d in [(15.6, 3.6), (25.6, 3.6), (34.4, 5.4)]:
        put(out, theme("show_sting"), at - 0.5, 0.4)
        put(out, applause(d), at, 0.55)
    return out


def gong():
    t = np.arange(int(2.5 * RATE)) / RATE
    return norm(sum(np.sin(2 * np.pi * f * t) * a * np.exp(-t / d) for f, a, d in ((98, 1.0, 1.2), (163, 0.7, 0.9), (231, 0.5, 0.7), (347, 0.3, 0.5), (512, 0.2, 0.3))) * np.minimum(1.0, t / 0.004))


def calouros():
    """O programa de calouros: a moça canta com o pianista, o gongo corta, a plateia lamenta e ri."""
    out = np.zeros(int(SEC * RATE))
    host = who(132, 1.01, 0.105, 0.42, (3, 6), 0.07, "animado", lex=lexicon(2), say=0.15, brand=0.3, **HOST)
    put(out, theme("show_sting"), 0.2, 0.5)
    put(out, applause(3.0), 1.2, 0.4)
    put(out, hall(speech(6.2, host, (0.2, 0.4))), 3.8)
    put(out, hall(theme("calouro")), 10.4, 0.6)
    put(out, hall(gong()), 20.4, 0.7)
    put(out, hall(ooh(1.6, "a")), 20.8, 0.35)
    for _ in range(6):
        put(out, laugh(rng.uniform(120, 260), rng.uniform(0.95, 1.2), int(rng.integers(4, 7))), 21.4 + rng.uniform(0.0, 1.4), 0.22)
    put(out, hall(speech(6.6, host, (0.2, 0.4))), 23.8)
    put(out, hall(chorus(host["lex"][0])), 30.4, 0.55)
    put(out, theme("show_sting"), 31.4, 0.4)
    put(out, applause(7.0), 31.9, 0.55)
    return out


def perguntas():
    """O programa de perguntas: ele pergunta, o relógio corre, a moça responde com medo, e toca a campainha do
    acerto (e as palmas) ou a buzina do erro (e o "aaah")."""
    out = np.zeros(int(SEC * RATE))
    host = who(140, 1.02, 0.11, 0.4, (3, 6), 0.07, "animado", endings={"pergunta": 0.7, "continua": 0.3}, air=0.3, lex=lexicon(2), say=0.15)
    guest = who(196, 1.15, 0.14, 0.25, (1, 2), 0.14, "suave", endings={"pergunta": 0.4, "afirma leve": 0.6}, hesitate=0.35)
    put(out, theme("show_sting"), 0.2, 0.5)
    put(out, applause(2.6), 1.2, 0.4)
    at = 4.2
    for right in (True, False, True):
        y, _ = line(host)
        put(out, hall(y), at)
        at += len(y) / RATE + 0.3
        for k in range(6):   # o relógio
            put(out, tone(hz("E5" if k % 2 else "C5"), 0.08, "bell"), at + k * 0.42, 0.2)
        ans = at + rng.uniform(1.0, 1.8)
        y, _ = line(guest)
        put(out, hall(y), ans, 0.85)
        at = max(at + 6 * 0.42, ans + len(y) / RATE) + 0.35
        if right:
            for k in range(2):
                put(out, tone(hz("E5"), 0.3, "bell"), at + 0.18 * k, 0.4)
            put(out, applause(2.6), at + 0.3, 0.5)
            at += 3.1
        else:
            put(out, tone(hz("A2"), 0.7, "brass"), at, 0.45)
            put(out, hall(ooh(1.2, "a")), at + 0.3, 0.3)
            at += 2.2
    if SEC - at > 6.5:
        put(out, hall(speech(SEC - at - 4.0, dict(host, **HOST), (0.2, 0.4))), at)
    put(out, theme("show_sting"), SEC - 5.0, 0.4)
    put(out, applause(4.4), SEC - 4.5, 0.55)
    return out


def futebol():
    """O jogo com gol: a narração, o lance, o grito e a torcida."""
    out = np.zeros(int(SEC * RATE))
    caster = who(150, 1.0, 0.095, 0.3, (4, 8), 0.14, "rouco", endings=MATCH, air=0.5, lex=lexicon(4), say=0.35)   # os jogadores
    put(out, crowd(SEC), 0.0, 0.3)
    put(out, speech(24, caster, (0.15, 0.4)), 0.5, 1.5)
    put(out, speech(5, dict(caster, f0=175, rate=0.085, lively=0.4, words=(5, 9), endings={"continua": 0.7, "enfase": 0.3}), (0.1, 0.2)), 24.0, 1.1)   # o lance
    goal = vowel((190, 230), 4.5, "o", 1.0, False, 0.12)
    goal *= np.minimum(1.0, np.arange(len(goal)) / (0.15 * RATE)) * np.minimum(1.0, np.arange(len(goal))[::-1] / (0.4 * RATE))
    put(out, goal, 29.2, 1.2)
    n = int(10.5 * RATE)
    roar = crowd(10.5) * np.minimum(1.0, np.arange(n) / (0.8 * RATE)) * np.minimum(1.0, (n - np.arange(n)) / (2.0 * RATE))
    put(out, roar, 29.4, 0.8)
    put(out, speech(5.5, dict(caster, f0=160, lively=0.35, words=(4, 7)), (0.15, 0.3)), 34.2)
    return out


def quase_gol():
    """O jogo sem gol: a narração, o comentarista, o lance, o "uuuh" da torcida, o apito e a conversa dos dois."""
    out = np.zeros(int(SEC * RATE))
    players = lexicon(4)
    caster = who(142, 1.0, 0.1, 0.3, (4, 8), 0.14, "rouco", endings=MATCH, air=0.5, lex=players, say=0.35)
    expert = who(104, 0.95, 0.14, 0.18, (3, 6), 0.1, "grave", endings={"afirma": 0.5, "afirma leve": 0.3, "suspensa": 0.2}, hesitate=0.12, lex=players, say=0.25, laughs=0.1)
    put(out, crowd(SEC), 0.0, 0.3)
    put(out, speech(12.5, caster, (0.15, 0.4)), 0.5, 1.4)
    put(out, speech(7.0, expert, (0.3, 0.7)), 13.2, 1.2)
    put(out, speech(5.2, dict(caster, f0=172, rate=0.085, lively=0.4, words=(5, 9), endings={"continua": 0.7, "enfase": 0.3}), (0.1, 0.2)), 20.4, 1.2)
    put(out, crowd(4.0) * np.hanning(int(4.0 * RATE)), 24.6, 0.6)
    put(out, ooh(1.9, "u", 30, (110, 300), 0.6), 25.6, 0.9)
    t = np.arange(int(0.8 * RATE)) / RATE   # o apito do juiz
    put(out, np.sin(2 * np.pi * 2750 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 38 * t)) * np.hanning(len(t)), 28.6, 0.2)
    put(out, speech(5.0, dict(caster, lively=0.25), (0.2, 0.5)), 29.4, 1.3)
    put(out, speech(5.2, expert, (0.3, 0.7)), 34.6, 1.2)
    return out


def radio_valsa():
    """O rádio com a valsa, e o locutor entrando no fim."""
    out = np.zeros(int(SEC * RATE))
    n = int(29 * RATE)
    w = waltz(29)
    w *= np.minimum(1.0, (n - np.arange(n)) / (4.0 * RATE))
    put(out, w, 0.0, 0.8)
    put(out, theme("station"), 27.8, 0.45)
    put(out, speech(9.0, who(104, 0.96, 0.14, 0.2, (3, 5), 0.1, "veludo", endings=RADIO, hesitate=0.06, air=0.6, lex=lexicon(2), say=0.2), (0.4, 0.8)), 31.0)
    return out


def radio(name):
    """O rádio com uma das músicas (`SONGS`): a calma inteira e o locutor depois; a agitada com ele por cima da entrada."""
    cfg = SONGS[name]
    out = np.zeros(int(SEC * RATE))
    dj = who(*cfg["dj"], endings=RADIO if name.startswith("calm") else SHOW, hesitate=0.06, air=0.5, lex=lexicon(2), say=0.2)
    music = song(cfg, 30.0 if name.startswith("calm") else SEC)
    n = len(music)
    if name.startswith("calm"):
        put(out, music * np.minimum(1.0, (n - np.arange(n)) / (4.0 * RATE)), 0.0, 0.8)
        put(out, theme("station"), 28.8, 0.45)
        put(out, speech(8.6, dj, (0.4, 0.8)), 31.2)
    else:
        talk = cfg["intro"] * 16 * 60.0 / cfg["bpm"] / 4
        g = np.ones(n)
        g[:int(talk * RATE)] = 0.5
        put(out, music * moving(g, None, 0.3) * np.minimum(1.0, (n - np.arange(n)) / (2.5 * RATE)), 0.0, 0.8)
        put(out, speech(talk + 0.8, dj, (0.15, 0.3)), 0.2, 0.9)
    return out


## Os intervalos: o jingle de cada reclame e a voz que o anuncia; no da canção de ninar, uma criança repete o nome.
ADS = [[("ad_1", (240, 1.22, 0.105, 0.38, (3, 6), 0.08, "animado")), ("ad_2", (134, 1.06, 0.11, 0.3, (3, 6), 0.05, "empostado")), ("ad_3", (190, 1.12, 0.12, 0.3, (3, 6), 0.16, "suave"))],
       [("ad_4", (150, 1.04, 0.1, 0.4, (3, 6), 0.07, "animado")), ("ad_5", (205, 1.15, 0.125, 0.28, (3, 5), 0.14, "suave")), ("ad_6", (108, 0.97, 0.12, 0.24, (3, 6), 0.08, "veludo"))]]


def comercial(k=0):
    """Três reclames, cada um com o seu jingle, o seu locutor e o nome do produto repetido."""
    out = np.zeros(int(SEC * RATE))
    slot = SEC / 3
    for i, (name, voice) in enumerate(ADS[k]):
        product = lexicon(1)
        jingle = theme(name)
        at = i * slot + 0.3
        put(out, jingle, at, 0.5)
        at += len(jingle) / RATE - 0.5
        kid = name == "ad_5"
        put(out, speech((i + 1) * slot - at - (1.5 if kid else 0.2), who(*voice, endings=AD, lex=product, say=0.2, brand=0.6), (0.2, 0.4)), at)
        if kid:
            put(out, phrase(305, 1.4, 0.13, 0.42, (1, 1), 0.12, "clara", "enfase", lex=product, brand=1.0), (i + 1) * slot - 1.3, 0.8)
    return out


# ---- os filmes: a trilha, os ruídos da cena e as falas curtas
def shot():
    t = np.arange(int(0.5 * RATE)) / RATE
    return norm(filt(rng.uniform(-1, 1, len(t)), "bandpass", (250, 2800)) * np.exp(-t / 0.05) + np.sin(2 * np.pi * 90 * t) * np.exp(-t / 0.04))


def blast():
    t = np.arange(int(2.2 * RATE)) / RATE
    return norm(filt(rng.uniform(-1, 1, len(t)), "lowpass", 260, 3) * np.exp(-t / 0.6) * np.minimum(1.0, t / 0.01)
        + 0.3 * filt(rng.uniform(-1, 1, len(t)), "bandpass", (300, 1500)) * np.exp(-t / 0.25))


def engine(dur, f=(55, 120)):
    """O motor do carro, acelerando."""
    n = int(dur * RATE)
    ph = np.cumsum(np.linspace(f[0], f[1], n) * (1.0 + 0.04 * slow(n, 0.3, 0.2)) / RATE)
    x = norm(filt(2 * (ph % 1.0) - 1 + 0.4 * (2 * ((ph * 0.5) % 1.0) - 1), "lowpass", 500) + 0.2 * filt(rng.uniform(-1, 1, n), "lowpass", 300))
    return x * np.minimum(1.0, np.arange(n) / (0.5 * RATE)) * np.minimum(1.0, np.arange(n)[::-1] / (0.8 * RATE))


def skid(dur=0.9):
    n = int(dur * RATE)
    return norm(filt(rng.uniform(-1, 1, n), "bandpass", (1300, 2300)) * (0.4 + 0.6 * slow(n, 0.06, 0.04))) * np.hanning(n)


def hooves(dur, every=0.36):
    """O cavalo a galope: três batidas e o intervalo."""
    out = np.zeros(int(dur * RATE))
    at = 0.0
    while at < dur - 0.4:
        for off in (0.0, 0.09, 0.18):
            put(out, knock(rng.uniform(140, 190), 0.05, (300, 1400)), at + off, rng.uniform(0.6, 1.0))
        at += every * rng.uniform(0.95, 1.05)
    return out * np.minimum(1.0, np.arange(len(out)) / (1.0 * RATE)) * np.minimum(1.0, np.arange(len(out))[::-1] / (1.5 * RATE))


def slide(up=True):
    """O apito de êmbolo da comédia."""
    n = int(0.55 * RATE)
    f = np.linspace(450, 1500, n) if up else np.linspace(1500, 400, n)
    return np.sin(2 * np.pi * np.cumsum(f / RATE)) * np.hanning(n)


def crash():
    t = np.arange(int(1.1 * RATE)) / RATE
    x = filt(rng.uniform(-1, 1, len(t)), "bandpass", (300, 3000)) * np.exp(-t / 0.22)
    for _ in range(6):
        put(x, tone(rng.uniform(900, 2600), 0.25, "bell"), rng.uniform(0.05, 0.6), 0.25)
    return norm(x)


def shout(f0, vw="a"):
    return vowel((f0 * 1.2, f0 * 0.9), rng.uniform(0.12, 0.2), vw, 1.0, False, 0.25)


def duck(music, spans, to=0.55):
    """A trilha baixa enquanto falam (`spans`: de quando a quando, s)."""
    g = np.ones(len(music))
    for a, b in spans:
        g[int(a * RATE):int(b * RATE)] = to
    return music * moving(g, None, 0.4)


def filme_acao():
    """Ação: as cordas martelando, os metais, a perseguição de carro, os tiros, a explosão e os gritos curtos."""
    out = np.zeros(int(SEC * RATE))
    music = np.zeros(int(SEC * RATE))
    step = 60.0 / 152 / 2
    riff = "D3 D3 F3 D3 D3 A2 C3 D3".split()
    for i in range(int((SEC - 1.0) / step)):
        put(music, tone(hz(riff[i % 8]), step * 0.9, "strings", 0.01), i * step, 0.22 * (1.3 if i % 8 == 0 else 1.0))
        if i % 16 == 0:
            put(music, drum("timp", hz("D2")), i * step, 0.5)
    for at, chord in [(3.2, "D4+F4+A4"), (9.6, "A#3+D4+F4"), (19.0, "G3+A#3+D4"), (26.4, "A3+C#4+E4"), (31.0, "D4+F4+A4"), (35.4, "A#3+D4+F4")]:
        for nt in chord.split("+"):
            put(music, tone(hz(nt), 1.2, "brass"), at, 0.2)
    for k in range(18):   # a caixa rufando até a explosão
        put(music, drum("snare"), 25.4 + k * 0.1, 0.12 + 0.012 * k)
    for nt in "D3+A3+D4+F4".split("+"):
        put(music, tone(hz(nt), 2.3, "brass"), 37.4, 0.25)
    put(out, duck(norm(room(music)), [(9.3, 14.6), (19.4, 25.2), (30.0, 34.2)]), 0.0, 0.6)
    put(out, engine(9.0), 0.2, 0.3)
    for at in (4.4, 8.2):
        put(out, skid(), at, 0.2)
    men = (who(118, 0.98, 0.1, 0.4, (1, 3), 0.1, "rouco", endings=TENSE), who(98, 0.93, 0.105, 0.36, (1, 3), 0.1, "grave", endings=TENSE))
    lines(out, men, 9.6, 14.6, (0.2, 0.6))
    for at in (15.0, 15.4, 16.1, 16.3, 17.5, 18.2, 18.5, 34.5, 34.9, 35.2):
        put(out, room(shot()), at + rng.uniform(-0.05, 0.05), rng.uniform(0.45, 0.7))
    lines(out, men, 19.6, 25.2, (0.3, 0.8))
    put(out, room(blast()), 27.3, 0.9)
    lines(out, men, 30.2, 34.2, (0.2, 0.5))
    return out


def filme_aventura():
    """Aventura: o tema do herói nos metais, o galope, o duelo de espadas e as falas de quem manda."""
    out = np.zeros(int(SEC * RATE))
    music = np.zeros(int(SEC * RATE))
    put(music, theme("adventure"), 0.2, 0.9)
    put(music, theme("adventure"), 28.4, 0.9)
    for k in range(int(SEC / 0.6)):   # o galope da orquestra: uma batida longa e duas curtas
        put(music, drum("timp", hz("C3" if k % 4 else "G2")), k * 0.6, 0.3)
        for off in (0.3, 0.45):
            put(music, drum("kick"), k * 0.6 + off, 0.2)
    for nt in "E3+G3+A#3+C#4".split("+"):   # o perigo, durante o duelo
        put(music, tone(hz(nt), 7.4, "strings", 0.8, 0.09), 20.0, 0.16)
    put(out, duck(norm(music), [(10.0, 19.2), (31.0, 36.6)], 0.4), 0.0, 0.6)
    put(out, hooves(11.0), 0.0, 0.3)
    n = int(SEC * RATE)
    put(out, filt(rng.uniform(-1, 1, n), "bandpass", (200, 700)) * (0.3 + 0.7 * slow(n, 0.8, 1.2)), 0.0, 0.05)   # o vento
    hero = who(126, 1.02, 0.115, 0.3, (2, 5), 0.06, "empostado", endings=TENSE)
    lady = who(214, 1.17, 0.12, 0.34, (2, 4), 0.1, "clara", endings=DRAMA)
    villain = who(96, 0.92, 0.13, 0.3, (2, 4), 0.1, "rouco", endings=TENSE, laughs=0.5)
    lines(out, (hero, lady), 10.2, 19.0, (0.3, 0.7))
    y, _ = line(villain)
    put(out, y, 19.6)
    for _ in range(11):   # as espadas e o esforço
        at = rng.uniform(21.6, 27.2)
        put(out, room(tone(rng.uniform(1100, 1900), 0.3, "bell")), at, 0.3)
        if rng.random() < 0.5:
            put(out, shout(rng.choice([126, 96]), "e"), at + 0.1, 0.35)
    put(out, room(knock(80, 0.25, (60, 500))), 27.5, 0.6)
    put(out, vowel((110, 70), 0.9, "a", 0.92, False, 0.2), 27.6, 0.5)   # o vilão cai
    lines(out, (lady, hero), 31.2, 36.6, (0.4, 0.9))
    put(out, hooves(5.0), 35.0, 0.25)
    return out


def filme_romance():
    """Romance: cordas e piano devagar, os dois falando baixo, com silêncios e suspiros, e a música crescendo no fim."""
    out = np.zeros(int(SEC * RATE))
    music = song(dict(bpm=60, key="F", scale="major", center="C5", lead="strings", hold=1.0, gain=0.35, intro=1,
        chords=[("F2", "M"), ("D2", "m"), ("A#2", "M"), ("C3", "7")], bass=("piano", "1...............", 0.4),
        comp=[("piano", "x.x.x.x.x.x.x.x.", 0.22, 2, True)], pad=("strings", 0.18, 2),
        rhythms=["x-----------x---x---------------", "x-------x-------x-----------....", "....x---x---x---x---------------"]), SEC)
    n = len(music)
    put(out, music * (0.55 + 0.45 * np.clip((np.arange(n) / RATE - 31.0) / 5.0, 0.0, 1.0)), 0.0, 0.7)
    ela = who(184, 1.12, 0.16, 0.26, (2, 4), 0.18, "suave", endings=DRAMA, hesitate=0.1, tremor=0.5, whisper=0.35, dyn=0.3)
    ele = who(100, 0.94, 0.17, 0.2, (2, 4), 0.12, "veludo", endings=DRAMA, hesitate=0.08, whisper=0.3, dyn=0.3)
    at, k, end = 5.0, 0, ""
    while at < 31.0:
        v, other = (ela, ele)[k % 2], (ele, ela)[k % 2]
        y, end = line(v, end)
        put(out, y, at, 0.85)
        at += len(y) / RATE + rng.uniform(1.0, 2.4)
        if rng.random() < 0.45:
            put(out, sigh(other) if rng.random() < 0.6 else hm(other), at - 0.9, 0.3)
        k += 1
    return out


def filme_comedia():
    """Comédia (sem risada gravada): a música saltitante, os dois falando depressa um por cima do outro, o apito de
    êmbolo, o tombo e a louça quebrada."""
    out = np.zeros(int(SEC * RATE))
    c, g, f = ("C2", "M"), ("G2", "7"), ("F2", "M")
    music = song(dict(bpm=132, key="C", scale="major", center="G5", lead="flute", hold=0.7, gain=0.35, intro=2,
        chords=[c, c, g, g, g, g, c, c, c, c, f, f, g, g, c, c], drums=[("kick", "x.......x.......", 0.3), ("hat", "....x.......x...", 0.2)],
        bass=("brass", "1...5...1...5...", 0.3), comp=[("piano", "....x.......x...", 0.25, 2, False)],
        rhythms=["x.x.x.xxx.x.x---x.x.x.xxx-x-x---", "x-..x-..x.x.x.x.x-..x-..x---....", "x.xxx.x.x-x-x-..x.xxx.x.x---...."]), SEC)
    talk = [(6.8, 13.4), (16.0, 21.4), (24.0, 29.2), (31.0, 35.2)]
    put(out, duck(music, talk, 0.5), 0.0, 0.6)
    ele = who(168, 1.04, 0.085, 0.45, (2, 5), 0.08, "animado", endings=FIGHT, hesitate=0.12)
    ela = who(262, 1.22, 0.088, 0.45, (2, 5), 0.1, "clara", endings=FIGHT)
    for a, b in talk:
        lines(out, (ele, ela), a, b, (-0.25, 0.3))
    for at, up in ((5.9, True), (14.2, False), (29.8, True)):
        put(out, slide(up), at, 0.3)
    for at in (14.8, 36.0, 36.5):
        put(out, room(knock(rng.uniform(250, 330), 0.12, (200, 900))), at, 0.6)
    put(out, room(crash()), 22.0, 0.6)
    return out


## Tudo o que o vizinho ouve: o nome do arquivo (o tipo e o número, `Sfx.NEIGHBOR_CLIPS`) e o programa.
PROGRAMS = [("news_1", noticiario), ("news_2", plantao), ("news_3", jornal_dupla),
    ("soap_1", lambda: novela(1)), ("soap_2", lambda: novela(2)), ("soap_3", lambda: novela(3)),
    ("show_1", auditorio), ("show_2", calouros), ("show_3", perguntas), ("match_1", futebol), ("match_2", quase_gol),
    ("ads_1", lambda: comercial(0)), ("ads_2", lambda: comercial(1)),
    ("film_1", filme_acao), ("film_2", filme_aventura), ("film_3", filme_romance), ("film_4", filme_comedia),
    ("calm_1", radio_valsa), ("calm_2", lambda: radio("calm_2")), ("calm_3", lambda: radio("calm_3")),
    ("hit_1", lambda: radio("hit_1")), ("hit_2", lambda: radio("hit_2")), ("hit_3", lambda: radio("hit_3")), ("hit_4", lambda: radio("hit_4"))]


# ---------------------------------------------------------------- o aparelho e a parede
def tv_set(x):
    """O alto-falante pequeno do aparelho: sem grave, sem brilho, um pouco saturado."""
    x = filt(filt(x, "highpass", 220), "lowpass", 3600)
    return np.tanh(x / np.percentile(np.abs(x), 99.9) * 1.2)   # (pelo pico: o volume mexido não é desfeito)


def wall(x):
    """Ouvido do cômodo ao lado: os agudos ficam na parede e o som chega com o eco da sala de lá."""
    wet = x.copy()
    for d, g in ((0.023, 0.35), (0.041, 0.28), (0.067, 0.2), (0.109, 0.12)):
        k = int(d * RATE)
        wet[k:] += x[:-k] * g
    return filt(filt(wet, "lowpass", 900, 3), "highpass", 150)


def ride(x, moves):
    """O vizinho mexe no volume: `moves`, (quando, s; para quanto), em dois ou três toques no botão."""
    g = np.ones(len(x)) * moves[0][1]
    for (at, to), (_, was) in zip(moves[1:], moves):
        for k in range(3):
            g[int((at + 0.22 * k) * RATE):] = was + (to - was) * (k + 1) / 3
    return x * moving(g, None, 0.06)


def static(n):
    """O chiado do aparelho, que nunca é parelho, e o zumbido da tomada."""
    t = np.arange(n) / RATE
    return rng.uniform(-1, 1, n) * (0.6 + 0.4 * slow(n, 0.7, 1.0)) * 0.016 + (np.sin(2 * np.pi * 60 * t) + 0.5 * np.sin(2 * np.pi * 120 * t)) * 0.004


def tuning(x, sec=2.8):
    """O vizinho gira o botão: chiado, um pedaço de duas outras estações, chiado, e para nesta."""
    n = int(sec * RATE)
    x = x.copy()
    x[:n] *= np.clip((np.arange(n) / RATE - (sec - 0.25)) / 0.2, 0.0, 1.0)
    gate = np.ones(n)
    other = (speech(3.0, who(140, 1.05, 0.1, 0.3, (4, 7), 0.07, "animado"), (0.1, 0.2)),
             theme("show"))
    at = 0.35
    for snd in other:
        d = rng.uniform(0.55, 0.85)
        a, b = int(at * RATE), int((at + d) * RATE)
        k0 = int(0.7 * RATE)
        x[a:b] += norm(snd)[k0:k0 + b - a] * np.minimum(1.0, np.minimum(np.arange(b - a), np.arange(b - a)[::-1]) / (0.05 * RATE)) * 0.8
        gate[a:b] = 0.25
        at += d + rng.uniform(0.3, 0.5)
    gate[-int(0.3 * RATE):] = 0.0
    x[:n] += rng.uniform(-1, 1, n) * moving(gate, None, 0.05) * 0.2
    return x


def knock(f, dur, band):
    n = int(dur * RATE)
    return norm(filt(rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / (n * 0.22)), "bandpass", band) + 0.6 * np.sin(2 * np.pi * f * np.arange(n) / RATE) * np.exp(-np.arange(n) / (n * 0.15)))


def cough():
    out = np.zeros(int(0.9 * RATE))
    at = 0.0
    for k in range(int(rng.integers(2, 4))):
        n = int(rng.uniform(0.09, 0.15) * RATE)
        e = np.exp(-np.arange(n) / (n * 0.3)) * np.minimum(1.0, np.arange(n) / (0.008 * RATE))
        put(out, norm(filt(rng.uniform(-1, 1, n) * e, "bandpass", (350, 1900))), at, 1.0 - 0.25 * k)
        at += rng.uniform(0.2, 0.28)
    return out


def chair():
    """A cadeira arrastada no assoalho: o ronco da madeira, aos trancos."""
    n = int(rng.uniform(0.5, 0.8) * RATE)
    return norm(filt(rng.uniform(-1, 1, n), "bandpass", (140, 700)) * slow(n, 0.05, 0.03) ** 2 * np.sin(np.pi * np.arange(n) / n))


def steps(count=4):
    out = np.zeros(int((count * 0.6 + 0.5) * RATE))
    for k in range(count):
        put(out, knock(rng.uniform(70, 95), 0.12, (60, 400)), k * rng.uniform(0.5, 0.58), rng.uniform(0.7, 1.0))
    return out


def clink():
    """A xícara no pires."""
    out = np.zeros(int(0.6 * RATE))
    for at in (0.0, rng.uniform(0.09, 0.16)):
        put(out, tone(rng.uniform(2300, 2900), 0.3, "bell"), at, rng.uniform(0.5, 1.0))
    return out


def laugh(f0=150, tract=1.0, n_ha=5):
    """A risada de quem assiste: "ha ha ha", cada um mais baixo e mais fraco."""
    out = np.zeros(int((n_ha * 0.2 + 0.4) * RATE))
    for k in range(n_ha):
        f = f0 * (1.25 - 0.07 * k) * rng.uniform(0.96, 1.04)
        put(out, vowel((f, f * 0.85), rng.uniform(0.09, 0.13), "a", tract, False, 0.3), k * rng.uniform(0.17, 0.21), 1.0 - 0.13 * k)
    return out


def cheer(f0=170):
    """O vizinho no gol: um grito comprido e duas palmas."""
    out = np.zeros(int(2.4 * RATE))
    y = vowel((f0, f0 * 1.25), 1.3, "e", 1.0, False, 0.2)
    put(out, y * np.minimum(1.0, np.arange(len(y))[::-1] / (0.3 * RATE)), 0.0)
    for at in (1.45, 1.75, 2.02):
        put(out, knock(1200, 0.05, (800, 2600)), at, 0.6)
    return out


## O aparelho de alguns programas: os toques no volume (os outros, sorteados).
SETS = {"news_1": dict(moves=[(0, 1.0), (23.6, 0.72)]), "soap_1": dict(moves=[(0, 0.75), (15.0, 1.0)]),
    "match_1": dict(moves=[(0, 1.0), (21.5, 1.3)]), "show_1": {}, "calm_1": {}, "ads_1": dict(moves=[(0, 1.0), (2.5, 0.65)])}
## Quem está na sala de lá: o som, quando (s) e a força (nos outros programas, sorteados). Não passa pelo
## alto-falante; passa pela parede.
HOME = {"news_1": [(cough, 12.0, 0.3), (chair, 30.5, 0.3)],
    "soap_1": [(clink, 11.0, 0.1), (cough, 22.5, 0.22), (clink, 33.0, 0.08)],
    "show_1": [(laugh, 15.9, 0.3), (lambda: laugh(215, 1.15, 6), 16.2, 0.22), (laugh, 26.0, 0.28), (clink, 31.0, 0.08)],
    "match_1": [(chair, 23.5, 0.3), (cheer, 29.6, 0.45), (lambda: laugh(150, 1.0, 4), 35.5, 0.2)],
    "calm_1": [(steps, 6.5, 0.3), (clink, 13.0, 0.1), (chair, 24.0, 0.25)],
    "ads_1": [(chair, 5.8, 0.3), (lambda: steps(5), 7.0, 0.3), (clink, 18.0, 0.09), (lambda: steps(4), 31.0, 0.28), (chair, 34.5, 0.28)]}
AROUND = [(cough, 0.26), (chair, 0.3), (steps, 0.3), (clink, 0.09)]


def device(x, name):
    """O programa como sai do aparelho do vizinho: com o volume mexido, o chiado e o zumbido."""
    x = norm(x)
    cfg = SETS.get(name)
    if cfg is None:
        cfg = dict(moves=[(0, 1.0), (rng.uniform(6.0, 30.0), rng.uniform(0.7, 1.25))]) if rng.random() < 0.5 else {}
    if "moves" in cfg:
        x = ride(x, cfg["moves"])
    return tv_set(x + static(len(x)))


def home(name, n):
    out = np.zeros(n)
    events = HOME.get(name)
    if events is None:
        events = [AROUND[int(rng.integers(len(AROUND)))] for _ in range(int(rng.integers(2, 5)))]
        events = [(fn, rng.uniform(3.0, SEC - 4.0), gain) for fn, gain in events]
    for fn, at, gain in events:
        put(out, room(fn()), at, gain)
    return out


def gadget(kind):
    """O aparelho na mão do vizinho: "on" (o estalo do botão e o chiado chegando com as válvulas), "off" (o estalo e o
    chiado sumindo), "tune_radio" (o botão girado por duas estações) e "tune_tv" (o seletor de canais, dois trancos)."""
    if kind in ("on", "off"):
        n = int((1.6 if kind == "on" else 0.7) * RATE)
        k = np.linspace(0.0, 1.0, n)
        x = static(n) * (k ** 2 if kind == "on" else (1.0 - k) ** 3) * 3.0
        put(x, knock(900, 0.03, (500, 3000)), 0.05, 0.5)
        if kind == "off":
            put(x, knock(60, 0.2, (40, 300)), 0.08, 0.4)
        return x
    if kind == "tune_radio":
        return tuning(np.zeros(int(3.2 * RATE)), 3.0)
    x = static(int(2.4 * RATE)) * 3.0
    for at, snd in ((0.2, theme("soap")), (1.05, speech(3.0, who(150, 1.04, 0.1, 0.35, (4, 7), 0.07, "animado"), (0.1, 0.2)))):
        put(x, knock(180, 0.06, (120, 1500)), at, 0.6)
        n = int(rng.uniform(0.5, 0.7) * RATE)
        k0 = int(0.8 * RATE)
        put(x, norm(snd)[k0:k0 + n] * np.minimum(1.0, np.minimum(np.arange(n), np.arange(n)[::-1]) / (0.04 * RATE)), at + 0.1, 0.6)
    put(x, knock(180, 0.06, (120, 1500)), 1.95, 0.6)
    return x


def fade(x, sec=0.6):
    n = int(sec * RATE)
    x = x.copy()
    x[:n] *= np.arange(n) / n
    x[-n:] *= np.arange(n)[::-1] / n
    return x


def save(name, dry, far, peak=0.0):
    """Grava o do jogo (`far`, pela parede: no volume médio `LEVEL`, ou no pico `peak`) e, com pasta, os de ouvir."""
    far = norm(far, peak) if peak else np.clip(far * (LEVEL / np.sqrt(np.mean(far ** 2))), -1.0, 1.0)
    sf.write(SAIDA / (name + ".ogg"), far.astype(np.float32), RATE, format="OGG", subtype="VORBIS")
    if len(sys.argv) > 1:
        for tag, x in (("aparelho", dry), ("parede", far)):
            wavfile.write("%s/%s_%s.wav" % (sys.argv[1], name, tag), RATE, (norm(x, 0.7) * 32767).astype(np.int16))
    print(name)


if __name__ == "__main__":
    SAIDA.mkdir(parents=True, exist_ok=True)
    only = sys.argv[2:]   # depois da pasta: só estes (cada som tem a sua semente, um não muda o outro)
    for i, (name, fn) in enumerate(PROGRAMS):
        if not only or name in only:
            rng = np.random.default_rng(7 + i)
            dry = device(fn(), name)
            dry = fade(dry + home(name, len(dry)))
            save(name, dry, fade(wall(dry)))
    for i, name in enumerate(("on", "off", "tune_radio", "tune_tv")):
        if not only or name in only:
            rng = np.random.default_rng(100 + i)
            dry = fade(filt(filt(gadget(name), "highpass", 220), "lowpass", 3600), 0.02)
            save(name, dry, fade(wall(dry), 0.02), 0.3 if name.startswith("tune") else 0.2)
