"""Os sons das cenas da rua que pedem voz, buzina ou sirene (`Sfx.STREET`, tocados pelo `Background`): os gritos de
quem assiste ao espancamento, os gemidos de quem apanha, as pancadas, a buzina do carro dos panfletos e a sirene da
viatura (longe, chegando e perdendo o giro quando ela para). Sintetizados, com a voz do gerador dos
vizinhos (`tools/vizinhos/gerar.py`) e o eco da rua (`street`): audio/street/<id>.ogg. A exceção é o rojão da bandeira,
montado de gravações CC0 do Freesound (`BURST`, baixadas sozinhas na primeira vez).

Rodar (o uv traz o soundfile, o numpy e o scipy):
    uv run --no-project --with soundfile --with numpy --with scipy python tools/rua/gerar.py [pasta]
Com a pasta, grava nela também os wav de ouvir: cada som e as três cenas montadas como no jogo (`cena_*`).
O sorteio tem semente fixa, uma por som: rodar de novo dá os mesmos. Mudou algo: ouça antes de trocar os do jogo.
"""
import subprocess
import sys
from pathlib import Path
import numpy as np
from scipy.signal import fftconvolve, butter, lfilter, resample_poly
from scipy.io import wavfile
import soundfile as sf

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "vizinhos"))
import gerar as nb   # a voz, os filtros e o `put`

SAIDA = Path(__file__).resolve().parent.parent.parent / "audio" / "street"
RATE = nb.RATE
PEAK = 0.9   # o pico de cada som gravado: o volume do jogo fica no `Sfx.VOL`
# A sirene de rotor (`Background.SIREN`, os mesmos números): o motor ligado `on` s a cada `period`, o giro subindo para
# `hi` Hz e, solto, caindo para `lo`; `down` é a altura em que começa o som dela desligada (`siren_down`).
SIREN = {"period": 4.0, "on": 1.2, "hi": 1000.0, "lo": 200.0, "tau_up": 0.55, "tau_down": 3.0, "down": 700.0}
rng = np.random.default_rng(1)

_ir_rng = np.random.default_rng(99)   # a mesma rua para todos os sons
_t = np.arange(int(1.0 * RATE)) / RATE
IR = nb.filt(nb.filt(_ir_rng.normal(0.0, 1.0, len(_t)) * np.exp(-_t / 0.16), "lowpass", 1600), "highpass", 200)
IR[:int(0.03 * RATE)] = 0.0
IR /= np.sqrt(np.sum(IR ** 2))


def seed(k):
    global rng
    rng = np.random.default_rng(k)
    nb.rng = rng


def street(x, far=0.5):
    """O som na rua, ouvido de dentro: as batidas de volta das fachadas dos dois lados (cada uma mais abafada), o
    resto espalhado da rua e o vidro da janela. `far`: 0 embaixo da janela, 1 no fim da rua (mais eco, menos agudo)."""
    n = len(x) + len(IR)
    dry = np.zeros(n)
    dry[:len(x)] = x
    wet = np.zeros(n)
    for d, g, cut in ((0.052, 0.42, 2600), (0.097, 0.33, 2100), (0.151, 0.26, 1700), (0.233, 0.2, 1400), (0.341, 0.13, 1100), (0.47, 0.08, 900)):
        k = int(d * RATE)
        wet[k:] += nb.filt(dry, "lowpass", cut)[:n - k] * g
    mix = dry * (1.0 - 0.45 * far) + wet * (0.55 + 0.5 * far) + fftconvolve(dry, IR)[:n] * (0.22 + 0.5 * far)
    return nb.filt(nb.filt(mix, "lowpass", 3400 - 2000 * far), "highpass", 140)


def curve(points, n):
    """A curva pelos pontos (em que fração do som, o valor), alisada."""
    k = np.linspace(0.0, 1.0, n)
    return nb.moving(np.interp(k, [p[0] for p in points], [p[1] for p in points]), None, 0.02)


def voice(f, vowels, tract, breath=0.15, rough=0.0, tense=0.3):
    """A voz forçada (grito, gemido): `f` a altura (Hz, por amostra), `vowels` as vogais ao longo do som ((fração,
    vogal)...), `rough` a garganta arranhando (um pulso sim, outro não, mais fraco, e a altura tremendo), `tense` a
    glote apertada de quem grita (mais agudos)."""
    n = len(f)
    f = f * (1.0 + 0.014 * np.sin(2 * np.pi * 6.1 * np.arange(n) / RATE) + rough * 0.05 * (nb.slow(n, 0.012, 0.01) - 0.5))
    turns = np.cumsum(f / RATE)
    ph = turns % 1.0
    opened, closing = 0.42 - 0.14 * tense, 0.16 - 0.07 * tense
    g = np.where(ph < opened, 0.5 * (1 - np.cos(np.pi * ph / opened)),
        np.where(ph < opened + closing, np.cos(np.pi * (ph - opened) / (2 * closing)), 0.0))
    src = np.diff(g, prepend=0.0) * (1.0 - rough * 0.5 * (np.floor(turns) % 2))
    air = rng.uniform(-1, 1, n) * (0.4 + g)
    src = src / np.sqrt(np.mean(src ** 2) + 1e-12) * (1 - breath) + air / np.sqrt(np.mean(air ** 2)) * breath
    at = [p[0] for p in vowels]
    y = src
    for i in range(3):   # a boca passando de uma vogal a outra (aberta de quem grita: o primeiro formante mais alto)
        fm = np.interp(np.linspace(0.0, 1.0, n), at, [nb.VOWEL[p[1]][i] * tract * (1.12 if i == 0 else 1.0) for p in vowels])
        y = nb.glide(y, nb.moving(fm, None, 0.03), nb.BW[i]) if i else nb.glide(src, nb.moving(fm, None, 0.03), nb.BW[0])
    return nb.norm(nb.resonator(y, nb.F4[0] * tract, nb.F4[1]))


def shape(x, attack, release, hold=1.0):
    n = len(x)
    k = np.arange(n) / RATE
    return x * np.minimum(1.0, k / attack) ** 0.7 * np.minimum(1.0, (k[::-1]) / release) * hold


def burst(dur, band, gain=1.0):
    """O estalo de uma consoante ou de uma pancada: ruído numa faixa, caindo depressa."""
    n = int(dur * RATE)
    return nb.norm(nb.filt(rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / (n * 0.25)), "bandpass", band)) * gain


def scream(kind, fs=1.0, tract=1.17, st=1.0):
    """A mulher que assiste: o grito comprido, o "ai!" curto e o grito que quebra no meio. Cada mulher com a voz dela:
    `fs` a altura (1: a primeira), `tract` o tamanho da boca, `st` o quanto ela segura o grito."""
    if kind == 0:   # comprido: sobe, segura lá em cima e cai
        n = int(1.25 * st * RATE)
        f = curve(((0.0, 520), (0.12, 860), (0.55, 900), (0.8, 780), (1.0, 560)), n) * fs
        y = voice(f, ((0.0, "a"), (1.0, "a")), tract, 0.14, 0.55, 0.9)
        return shape(y, 0.04, 0.3)
    if kind == 1:   # "ai!"
        n = int(0.55 * st * RATE)
        f = curve(((0.0, 600), (0.25, 820), (1.0, 640)), n) * fs
        y = voice(f, ((0.0, "a"), (0.45, "a"), (0.8, "i"), (1.0, "i")), tract, 0.12, 0.3, 0.8)
        return shape(y, 0.02, 0.16)
    n = int(0.95 * st * RATE)   # o que quebra: dois tempos, o segundo mais alto
    f = curve(((0.0, 560), (0.2, 760), (0.4, 700), (0.48, 620), (0.6, 940), (0.85, 900), (1.0, 640)), n) * fs
    y = voice(f, ((0.0, "a"), (0.42, "a"), (0.55, "e"), (1.0, "e")), tract, 0.16, 0.6, 0.9)
    return shape(y, 0.03, 0.25) * curve(((0.0, 1.0), (0.42, 0.9), (0.48, 0.35), (0.56, 1.0), (1.0, 1.0)), n)


def shout(kind):
    """O homem que assiste e protesta, de longe: "ei!", "ôôu!" e duas sílabas ("pá-ra")."""
    if kind == 0:
        n = int(0.42 * RATE)
        y = voice(curve(((0.0, 250), (0.2, 300), (1.0, 215)), n), ((0.0, "e"), (0.5, "e"), (1.0, "i")), 1.0, 0.12, 0.35, 0.8)
        return shape(y, 0.015, 0.14)
    if kind == 1:
        n = int(0.75 * RATE)
        y = voice(curve(((0.0, 230), (0.15, 285), (0.7, 265), (1.0, 190)), n), ((0.0, "o"), (0.7, "o"), (1.0, "u")), 0.98, 0.12, 0.4, 0.8)
        return shape(y, 0.03, 0.25)
    out = np.zeros(int(0.8 * RATE))
    nb.put(out, burst(0.025, (300, 2400)), 0.0, 0.5)   # o "p"
    n = int(0.26 * RATE)
    nb.put(out, shape(voice(curve(((0.0, 270), (0.3, 310), (1.0, 280)), n), ((0.0, "a"), (1.0, "a")), 1.0, 0.1, 0.35, 0.85), 0.012, 0.06), 0.02)
    n = int(0.34 * RATE)   # (o "r" é só a voz caindo um instante entre as duas)
    nb.put(out, shape(voice(curve(((0.0, 240), (0.4, 235), (1.0, 180)), n), ((0.0, "a"), (1.0, "a")), 1.0, 0.14, 0.3, 0.6), 0.03, 0.18), 0.31, 0.8)
    return out


def groan(kind):
    """Quem apanha: o grito curto de dor, o gemido de boca fechada e o ar que sai com o chute."""
    if kind == 0:
        n = int(0.34 * RATE)
        y = voice(curve(((0.0, 210), (0.2, 250), (1.0, 150)), n), ((0.0, "a"), (1.0, "a")), 1.0, 0.25, 0.7, 0.5)
        return shape(y, 0.012, 0.18)
    if kind == 1:
        n = int(0.5 * RATE)
        y = voice(curve(((0.0, 170), (0.3, 190), (1.0, 120)), n), ((0.0, "u"), (1.0, "o")), 1.0, 0.3, 0.6, 0.2)
        return shape(nb.filt(y, "lowpass", 900), 0.03, 0.3)
    n = int(0.3 * RATE)
    y = voice(curve(((0.0, 190), (1.0, 130)), n), ((0.0, "e"), (1.0, "a")), 1.0, 0.6, 0.8, 0.3)
    out = np.zeros(n)
    nb.put(out, burst(0.12, (400, 1800)), 0.0, 0.5)   # o ar saindo de uma vez
    return out + shape(y, 0.01, 0.2) * 0.8


def commotion(sec=16.0):
    """O converseiro de quem assiste ao espancamento: sete pessoas falando alto ao mesmo tempo, agitadas (a fala
    inventada dos vizinhos, depressa e em frases curtas), com gritos e protestos soltos por cima, mais juntos no meio
    (as pancadas); cresce quando o policial agarra o homem e vai morrendo quando ele é arrastado."""
    n = int(sec * RATE)
    out = np.zeros(n)
    people = [(245, 1.16, "clara"), (270, 1.18, "animado"), (215, 1.13, "suave"), (150, 1.02, "animado"), (128, 0.98, "grave"),
        (165, 1.04, "clara"), (290, 1.19, "clara")]
    for f0, tract, kind in people:
        v = nb.who(f0 * rng.uniform(0.96, 1.06), tract, rng.uniform(0.082, 0.1), rng.uniform(0.55, 0.8), (2, 5), 0.1, kind, dyn=0.35, air=0.1)
        y = nb.speech(sec + 2.0, v, (0.15, 0.7))[int(rng.uniform(0.0, 1.5) * RATE):][:n]
        out[:len(y)] += nb.norm(y) * rng.uniform(0.55, 1.0)
    out = nb.norm(out) * 0.75
    # os gritos soltos, espaçados: só dois de mulher, de duas mulheres diferentes e longe um do outro; o resto, protestos
    for at, fn, kind, more in ((0.16, shout, 1, ()), (0.3, scream, 1, (0.88, 1.12, 0.9)), (0.4, shout, 2, ()), (0.5, groan, 1, ()),
            (0.58, shout, 0, ()), (0.7, scream, 2, (1.1, 1.2, 0.8)), (0.8, shout, 1, ())):
        nb.put(out, fn(kind, *more), (at + rng.uniform(-0.02, 0.02)) * sec, rng.uniform(0.35, 0.6))
    t = np.arange(n) / RATE
    swell = 0.55 + 0.45 * np.exp(-((t - sec * 0.45) / (sec * 0.28)) ** 2)   # mais alto nas pancadas
    return out * np.minimum(1.0, t / 1.6) * np.minimum(1.0, t[::-1] / 4.0) * swell


def door():
    """A porta ou a janela de madeira batendo: a pancada, o caixilho e um resto de vidro tremendo."""
    n = int(0.3 * RATE)
    t = np.arange(n) / RATE
    out = np.sin(2 * np.pi * np.cumsum(72.0 * (1.0 + 0.9 * np.exp(-t / 0.015)) / RATE)) * np.exp(-t / 0.07)
    nb.put(out, burst(0.06, (250, 1700)), 0.0, 0.8)
    nb.put(out, nb.norm(nb.resonator(rng.uniform(-1, 1, n) * np.exp(-t / 0.05), 1450, 120)), 0.012, 0.18)
    return out


def megaphone(sec=22.0):
    """O toque de recolher: o aviso gravado que a viatura toca pelo megafone, a mesma frase três vezes (fala
    inventada, pausada, de quem dá ordem), mais alto quando ela passa no meio; e duas ou três janelas batendo na rua."""
    n = int(sec * RATE)
    t = np.arange(n) / RATE
    v = nb.who(118, 0.97, 0.125, 0.22, (3, 6), 0.06, "grave", dyn=0.1, air=0.0)
    notice = nb.norm(nb.speech(6.2, v, (0.25, 0.5)))   # o aviso: gravado uma vez, tocado igual
    say = np.zeros(n)
    for at in (0.8, 7.7, 14.6):
        nb.put(say, notice, at)
        nb.put(say, burst(0.05, (600, 2400)), at, 0.5)   # o estalo do aparelho a cada volta
    horn = nb.filt(nb.filt(say, "highpass", 450, 3), "lowpass", 2600, 3)
    horn = np.tanh(3.0 * horn / (np.percentile(np.abs(horn), 99.5) + 1e-9))
    horn = nb.norm(nb.resonator(horn, 1150, 400) + 0.7 * nb.resonator(horn, 1900, 500))   # a corneta
    out = street(horn * (0.3 + 0.7 * np.exp(-((t - 0.42 * sec) / (0.3 * sec)) ** 2)), 0.5)
    shut = np.zeros(n)
    for at in (5.2, 9.9, 13.4):
        nb.put(shut, door(), at + rng.uniform(-0.3, 0.3), rng.uniform(0.35, 0.6))
    out[:n] += street(shut, 0.7)[:n] * 0.9
    return out


def whistle(kind):
    """O apito de polícia, estridente: duas câmaras bem agudas batendo uma na outra, a bolinha trinando depressa e
    pouco ar. 0 um sopro comprido, 1 dois curtos."""
    def blast(dur):
        n = int(dur * RATE)
        t = np.arange(n) / RATE
        f = 2850.0 * (1.0 + 0.03 * np.minimum(1.0, t / 0.04))
        y = np.sin(2 * np.pi * np.cumsum(f / RATE)) + 0.9 * np.sin(2 * np.pi * np.cumsum(f * 1.09 / RATE))
        y = np.tanh(1.5 * y) * (0.4 + 0.6 * (np.sin(2 * np.pi * 52 * t) > -0.2)) + nb.filt(rng.uniform(-1, 1, n), "bandpass", (2400, 4200)) * 0.15
        return nb.norm(y) * np.minimum(1.0, t / 0.012) * np.minimum(1.0, t[::-1] / 0.04)
    if kind == 0:
        return blast(0.95)
    out = np.zeros(int(0.9 * RATE))
    nb.put(out, blast(0.22), 0.0)
    nb.put(out, blast(0.5), 0.34)
    return out


def order(kind):
    """A ordem gritada pelo policial: uma, duas ou três palavras secas (fala inventada)."""
    v = nb.who((165, 150, 180)[kind], (0.99, 0.97, 1.01)[kind], 0.095, 0.5, ((1, 2), (2, 3), (1, 1))[kind], 0.05, "grave", endings={"afirma": 1.0})
    y, _ = nb.line(v)
    return np.tanh(nb.norm(y) * 1.8)


def plea(kind):
    """A mulher que pede baixo quando levam os presos: só fala (inventada, como a dos vizinhos), uma frase curta e
    embargada, repetida mais fraca. Sem choro: sintetizado, ele soava a sopro, a grito e a cachorro."""
    v = nb.who((235, 215)[kind], (1.15, 1.13)[kind], 0.125, 0.45, (2, 3), 0.1, "suave", tremor=0.6, dyn=0.2, endings={"suspensa": 0.6, "afirma leve": 0.4})
    y, end = nb.line(v)
    z, _ = nb.line(v, end)
    out = np.zeros(len(y) + len(z) + int(0.8 * RATE))
    nb.put(out, nb.norm(y), 0.0)
    nb.put(out, nb.norm(z), len(y) / RATE + rng.uniform(0.35, 0.6), 0.7)
    return out


def baby(sec=12.0):
    """O bebê de colo chorando baixo e devagar, quase ninado: a boca muito curta (formantes lá em cima) e a voz aguda;
    cada choro sobe de leve e cai devagar, com uma pausa boa e o ar puxado antes do próximo. Começa resmungando."""
    out = np.zeros(int(sec * RATE))
    at, k = 0.3, 0
    while at < sec - 1.6:
        full = k >= 1   # o primeiro: um resmungo curto
        dur = rng.uniform(0.9, 1.3) if full else rng.uniform(0.3, 0.45)
        n = int(dur * RATE)
        t = np.arange(n) / RATE
        top = rng.uniform(500, 560) if full else rng.uniform(450, 490)
        f = curve(((0.0, top * 0.85), (0.15, top), (0.7, top * 0.86), (1.0, top * 0.66)), n)
        f = f * (1.0 + 0.015 * np.sin(2 * np.pi * 8.0 * t) * np.minimum(1.0, t / 0.4))
        y = voice(f, ((0.0, "e"), (0.2, "a"), (0.8, "a"), (1.0, "e")), 1.75, 0.1, 0.12, 0.6)
        nb.put(out, shape(y, 0.08, 0.3), at, (rng.uniform(0.7, 0.9) if full else 0.45) * min(1.0, (sec - at) / 3.5))
        at += dur + rng.uniform(0.25, 0.5)
        m = int(rng.uniform(0.12, 0.18) * RATE)   # o ar puxado, com um fio de voz
        nb.put(out, shape(voice(curve(((0.0, 720), (1.0, 840)), m), ((0.0, "i"), (1.0, "e")), 1.75, 0.4, 0.2, 0.3), 0.03, 0.05), at, 0.14)
        at += m / RATE + rng.uniform(0.3, 0.6)
        k += 1
    return out


def luggage(kind):
    """A mala posta no chão da Kombi: surda, com o estalo da alça."""
    n = int(0.25 * RATE)
    t = np.arange(n) / RATE
    out = np.sin(2 * np.pi * np.cumsum((84.0, 68.0)[kind] * (1.0 + 0.8 * np.exp(-t / 0.02)) / RATE)) * np.exp(-t / 0.09)
    nb.put(out, burst(0.07, (150, 900)), 0.0, 0.6)
    nb.put(out, burst(0.015, (1200, 2800)), 0.05, 0.15)
    return out


def shutter(sec=1.6):
    """A porta de aço da banca descendo: o ronco grave e contínuo da chapa correndo no trilho, sem trepidar, crescendo
    um pouco até o chão, e a pancada pesada com um resto curto de chapa."""
    n = int((sec + 1.0) * RATE)
    k = int(sec * RATE)
    t = np.arange(k) / RATE
    grind = nb.filt(rng.uniform(-1, 1, k), "bandpass", (130, 800))
    body = sum(nb.resonator(grind, f, 70) * g for f, g in ((220, 1.0), (390, 0.6), (610, 0.3)))   # a chapa grande ressoando
    roll = nb.norm(grind) * 0.7 + nb.norm(body) * 0.6
    out = np.zeros(n)
    out[:k] = roll * np.linspace(0.6, 1.0, k) * np.minimum(1.0, t / 0.12)
    slam = np.zeros(int(0.8 * RATE))
    ts = np.arange(len(slam)) / RATE
    slam += np.sin(2 * np.pi * np.cumsum(58.0 * (1.0 + 1.1 * np.exp(-ts / 0.02)) / RATE)) * np.exp(-ts / 0.11)   # o peso no chão
    nb.put(slam, burst(0.09, (120, 900)), 0.0, 0.9)
    ring = nb.filt(rng.uniform(-1, 1, len(slam)), "bandpass", (160, 600)) * np.exp(-ts / 0.16)
    slam += nb.norm(nb.resonator(ring, 205, 30)) * 0.35   # a chapa ainda soando, sem tremer
    nb.put(out, nb.norm(slam), sec, 1.3)
    return out


HI = 48000   # a taxa dos rojões, que são gravação (`RATES`)
# Os rojões são os únicos sons daqui que são gravação: sintetizado, o estouro não convencia. Cada tiro junta duas
# gravações CC0 do Freesound, alinhadas no pico: o corpo e o eco de um estouro de fogos numa cidade (`BODY`: cheio, com
# ~3 s de eco de verdade, contínuo) e o estalo seco de um rojão (`CRACK`). Só o rojão soava a tiro, fino; só o estouro
# de cidade não tinha o estalo. Escolhidos pelo espectrograma: estouros sozinhos (outros vêm em dobro ou com gente
# falando no eco).
BODY = ("613673", "unfa")             # "Three Outdoor Clean Explosions": 12,53, 34,70 e 42,76 s
CRACK = ("347906", "juliojunior77")   # "Fogos de artifício, rojão"
# O rojão de doze tiros: onze normais, que podem estourar juntos (uns colados, outros com um respiro, nunca no mesmo
# passo), e o último, forte, um pouco depois: o maior estouro da gravação, tocado mais devagar (mais grave e mais
# comprido) e na força toda. Os onze saem dos dois estouros menores e dos seis estalos limpos, cada um com a sua força
# e o seu tom, e com menos eco livre que o forte (onze ecos inteiros somados viravam um ronco que o engolia).
BURST = {"normal": 11, "bodies": (34.70, 42.76), "cracks": (30.47, 33.92, 37.78, 40.70, 45.47, 48.41),
    "close": (0.55, (0.0, 0.03)), "apart": (0.06, 0.16),   # a chance de o próximo estourar junto e os dois intervalos (s)
    "gain": (0.32, 0.55), "tone": (0.94, 1.15), "tail": 1.6,   # (a força baixa: estourando juntos eles se somam, e o forte tem de ser o maior)
    "strong": (12.53, 0.84, 3.3), "wait": (1.15, 1.35)}   # o forte: o estouro, o tom, o eco (s), e quanto vem depois do último normal (s)


def burst_shots():
    """Os doze tiros de um rojão (`BURST`), sorteados pela semente do som: (o estouro, o estalo, quando (s), a força,
    o tom, o eco (s))."""
    b = BURST
    shots, at = [], 0.0
    cracks = list(rng.permutation(b["cracks"])) * 2
    for k in range(b["normal"]):
        shots.append((b["bodies"][int(rng.integers(len(b["bodies"])))], cracks[k], at, rng.uniform(*b["gain"]), rng.uniform(*b["tone"]), b["tail"]))
        at += rng.uniform(*b["close"][1]) if rng.random() < b["close"][0] else rng.uniform(*b["apart"])
    last = shots[-1][2] + rng.uniform(*b["wait"])
    return shots + [(b["strong"][0], cracks[b["normal"]], last, 1.0, b["strong"][1], b["strong"][2])]


POWER = {"crack": 0.7, "bass": 0.9, "drive": 2.2, "roll": 0.18}   # o estalo e o grave somados, a saturação e a cauda posta por cima
FONTES = Path(__file__).resolve().parent.parent.parent / "build" / "rua" / "fontes"


def source(code, author):
    """A gravação do Freesound: em build/rua/fontes/<código>.<ext> o original baixado à mão (com conta no Freesound),
    quando houver; senão a prévia de qualidade alta, baixada sozinha (como `tools/ambiente/preparar.py`)."""
    for ext in ("wav", "flac", "aif", "aiff", "ogg"):
        if (FONTES / ("%s.%s" % (code, ext))).exists():
            return FONTES / ("%s.%s" % (code, ext))
    FONTES.mkdir(parents=True, exist_ok=True)
    page = subprocess.run(["curl", "-sL", "-A", "Mozilla/5.0", "https://freesound.org/people/%s/sounds/%s/" % (author, code)],
        capture_output=True, text=True, check=True).stdout
    url = page.split('data-ogg="', 1)[1].split('"', 1)[0].replace("-lq.ogg", "-hq.ogg")
    subprocess.run(["curl", "-sL", "-A", "Mozilla/5.0", "-o", str(FONTES / (code + ".ogg")), url], check=True)
    return FONTES / (code + ".ogg")


_loaded = {}


def recording(src):
    """A gravação `src` (o código e o autor no Freesound), em mono e na taxa dos rojões."""
    if src not in _loaded:
        x, rate = sf.read(source(*src))
        x = x.mean(axis=1) if x.ndim > 1 else x
        _loaded[src] = resample_poly(x, HI, rate) if rate != HI else x
    return _loaded[src]


def peak_at(x, at):
    """A amostra do pico do estouro que a lista diz estar em `at` s."""
    i0 = int((at - 0.06) * HI)
    return i0 + int(np.argmax(np.abs(x[i0:int((at + 0.12) * HI)])))


def rocket():
    """O rojão de doze tiros (`BURST`, `burst_shots`). Cada tiro: o corpo de um estouro de verdade com o eco dele por
    inteiro (os ecos se somam, como na rua), o estalo de um rojão no mesmo instante, o grave reforçado e tudo levado
    ao limite de quem grava alto (a saturação suave é o que dá a força: o estouro enche em vez de só estalar)."""
    p = POWER
    lead = int(0.05 * HI)
    shots = burst_shots()
    print("   tiros em", " ".join("%.2f" % x[2] for x in shots))
    out = np.zeros(int((max(when + tail for _, _, when, _, _, tail in shots) + 0.2) * HI))
    blo, alo = butter(2, 140 / (HI / 2), "lowpass")
    for body_at, crack_at, when, gain, tone, tail in shots:
        body = recording(BODY)
        k = peak_at(body, body_at)
        y = body[k - int(lead * tone):k + int(tail * tone * HI)]
        y = np.interp(np.arange(0, len(y) - 1, tone), np.arange(len(y)), y)   # (o tom: mais devagar, mais grave)
        y = y / np.max(np.abs(y))
        crack = recording(CRACK)
        k = peak_at(crack, crack_at)
        c = crack[k - lead:k + int(0.35 * HI)].copy()
        c *= np.minimum(1.0, np.arange(len(c))[::-1] / (0.15 * HI))
        i = int(np.argmax(np.abs(y))) - lead   # os dois picos juntos
        y[max(0, i):max(0, i) + len(c)] += c / np.max(np.abs(c)) * p["crack"]
        y += lfilter(blo, alo, y) * p["bass"]
        y = np.tanh(p["drive"] * y / np.max(np.abs(y))) / np.tanh(p["drive"])
        n = int(0.5 * len(y)) if tail < 2.5 else int(0.6 * HI)   # (o eco dos normais some mais cedo)
        y[-n:] *= np.arange(n)[::-1] / n
        y[:lead // 2] *= np.arange(lead // 2) / (lead // 2)
        i0 = int(when * HI)
        m = min(len(y), len(out) - i0)
        out[i0:i0 + m] += y[:m] * gain
    # Por cima, uma cauda contínua e fraca, que cola os três ecos num só e some aos poucos, os agudos primeiro.
    t = np.arange(int(3.0 * HI)) / HI
    noise = np.random.default_rng(99).normal(0.0, 1.0, len(t))
    ir = np.zeros(len(t))
    for band, tau, g in (((150, 700), 0.8, 0.75), ((700, 2500), 0.6, 0.85), ((2500, 7000), 0.3, 0.55)):
        b, a = butter(2, [band[0] / (HI / 2), band[1] / (HI / 2)], "bandpass")
        ir += lfilter(b, a, noise) * np.exp(-t / tau) * g
    ir *= np.minimum(1.0, t / 0.03) * np.minimum(1.0, t[::-1] / 0.8)
    tail = fftconvolve(out, ir / np.sqrt(np.sum(ir ** 2)))
    full = np.zeros(max(len(out), len(tail)))
    full[:len(out)] = out
    full[:len(tail)] += tail * p["roll"]
    last = np.nonzero(np.abs(full) > np.max(np.abs(full)) * 0.0005)[0][-1]   # sem o silêncio que sobra no fim
    return full[:last + int(0.1 * HI)]


def far_rocket():
    """O mesmo rojão ouvido de bem longe, de outro bairro: o ar come os agudos (o estalo vira um baque surdo), o
    ataque chega amolecido e o som vem mais pelo eco da cidade que direto. Fraco: o volume no jogo é baixo."""
    x = rocket()
    b, a = butter(2, 1500 / (HI / 2), "lowpass")
    y = lfilter(b, a, x)
    b, a = butter(2, 70 / (HI / 2), "highpass")
    y = lfilter(b, a, y)
    t = np.arange(int(2.5 * HI)) / HI
    b, a = butter(2, [120 / (HI / 2), 1200 / (HI / 2)], "bandpass")
    ir = lfilter(b, a, np.random.default_rng(98).normal(0.0, 1.0, len(t))) * np.exp(-t / 0.7) * np.minimum(1.0, t / 0.02) * np.minimum(1.0, t[::-1] / 0.8)
    tail = fftconvolve(y, ir / np.sqrt(np.sum(ir ** 2)))
    out = np.zeros(len(tail))
    out[:len(y)] = y * 0.6
    return out + tail * 0.8


SEEDS = {"rocket_far": "rocket", "rocket_far2": "rocket2"}   # os sons que usam a semente de outro: os mesmos doze tiros, de longe
RATES = {name: HI for name in ("rocket", "rocket2", "rocket_far", "rocket_far2", "cena_bandeira")}   # os sons fora da taxa dos outros (`RATE`)


def blow(kind):
    """A pancada: 0 e 1 o cassetete (seco, na roupa e no corpo), 2 o chute (mais surdo)."""
    n = int(0.22 * RATE)
    t = np.arange(n) / RATE
    f = (105, 88, 62)[kind]
    thud = np.sin(2 * np.pi * np.cumsum(f * (1.0 + 1.2 * np.exp(-t / 0.012)) / RATE)) * np.exp(-t / (0.05 if kind < 2 else 0.08))
    out = thud * (0.9 if kind < 2 else 1.0)
    nb.put(out, burst(0.03 if kind < 2 else 0.05, ((700, 2600), (500, 2000), (200, 900))[kind]), 0.0, (0.7, 0.55, 0.45)[kind])
    return out


def honk(dur):
    """A buzina do carro pequeno: dois discos (um par de notas fora de afinação), anasalada, com a altura cedendo um
    pouco no começo."""
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for f0, g in ((392.0, 1.0), (494.0, 0.8)):
        ph = np.cumsum(f0 * (1.0 - 0.03 * np.exp(-t / 0.03)) * (1.0 + 0.003 * np.sin(2 * np.pi * 31 * t)) / RATE)
        for k in range(1, 12):
            out += g * np.sin(2 * np.pi * k * ph + k) / k ** 0.55
    out = nb.resonator(out, 1150, 500) + 0.6 * nb.resonator(out, 2500, 700)   # o cone da buzina
    return nb.norm(np.tanh(nb.norm(out) * 1.6)) * np.minimum(1.0, t / 0.012) * np.minimum(1.0, t[::-1] / 0.03)


def horn(kind):
    """As buzinadas: "bi-bi", uma comprida e "bi-bi-biii"."""
    pattern = (((0.0, 0.13), (0.24, 0.2)), ((0.0, 0.85),), ((0.0, 0.11), (0.2, 0.11), (0.42, 0.6)))[kind]
    out = np.zeros(int((pattern[-1][0] + pattern[-1][1]) * RATE) + 1)
    for at, dur in pattern:
        nb.put(out, honk(dur), at)
    return out


def wail_hz(sec, coast_from=None):
    """A altura da sirene de rotor (Hz, por amostra) em `sec` s, do começo de um ciclo já no regime; de `coast_from`
    s em diante o motor fica desligado e o rotor só perde o giro."""
    s = SIREN
    start = s["lo"]
    for _ in range(40):   # o regime: onde o ciclo começa depois de muitos
        top = s["hi"] - (s["hi"] - start) * np.exp(-s["on"] / s["tau_up"])
        start = s["lo"] + (top - s["lo"]) * np.exp(-(s["period"] - s["on"]) / s["tau_down"])
    t = np.arange(int(sec * RATE)) / RATE
    p = t % s["period"]
    top = s["hi"] - (s["hi"] - start) * np.exp(-s["on"] / s["tau_up"])
    f = np.where(p < s["on"], s["hi"] - (s["hi"] - start) * np.exp(-p / s["tau_up"]), s["lo"] + (top - s["lo"]) * np.exp(-(p - s["on"]) / s["tau_down"]))
    if coast_from is not None:
        k = int(coast_from * RATE)
        f[k:] = 40.0 + (f[k] - 40.0) * np.exp(-(t[k:] - t[k]) / 1.15)
    return f, start, top


def rotor(f):
    """O som do rotor na altura `f`: o ar cortado pelas janelas dele (cheio de harmônicos), mais forte quanto mais
    depressa gira, com o sopro por cima."""
    n = len(f)
    ph = np.cumsum(f / RATE)
    out = np.zeros(n)
    for k in range(1, 8):
        out += np.sin(2 * np.pi * k * ph + 0.7 * k) / k ** 1.15 + 0.5 * np.sin(2 * np.pi * k * ph * 1.006) / k ** 1.3
    out += nb.filt(rng.uniform(-1, 1, n), "bandpass", (700, 2600)) * 0.25
    return nb.norm(out * (f / SIREN["hi"]) ** 1.5)


def siren(kind):
    """`far`: longe, vindo (o som comprido, que some sozinho); `near`: dois ciclos de perto; `down`: desligada."""
    p = SIREN["period"]
    if kind == "far":
        f, _, _ = wail_hz(4 * p)
        y = street(rotor(f), 1.0)
        return y * np.minimum(1.0, np.arange(len(y)) / (1.5 * RATE)) * np.minimum(1.0, np.arange(len(y))[::-1] / (3.0 * RATE))
    if kind == "near":
        f, _, _ = wail_hz(2 * p)
        return street(rotor(f), 0.25)
    n = int(3.6 * RATE)
    t = np.arange(n) / RATE
    f = 40.0 + (SIREN["down"] - 40.0) * np.exp(-t / 1.15)
    return street(rotor(f) * np.minimum(1.0, t / 0.05), 0.25)


SOUNDS = [   # (o nome do arquivo, quem faz, a distância na rua)
    ("scream", lambda: scream(0), 0.55), ("scream_1", lambda: scream(1, 0.9, 1.13), 0.55), ("scream_2", lambda: scream(2, 1.07, 1.2), 0.6),
    ("shout", lambda: shout(0), 0.6), ("shout_1", lambda: shout(1), 0.6), ("shout_2", lambda: shout(2), 0.6),
    ("groan", lambda: groan(0), 0.45), ("groan_1", lambda: groan(1), 0.45), ("groan_2", lambda: groan(2), 0.45),
    ("blow", lambda: blow(0), 0.45), ("blow_1", lambda: blow(1), 0.45), ("kick", lambda: blow(2), 0.45),
    ("horn", lambda: horn(0), 0.4), ("horn_1", lambda: horn(1), 0.4), ("horn_2", lambda: horn(2), 0.4),
    ("commotion", commotion, 0.6),
    ("siren_far", lambda: siren("far"), None), ("siren", lambda: siren("near"), None), ("siren_down", lambda: siren("down"), None),
    ("scream_3", lambda: scream(1, 1.1, 1.2, 1.25), 0.5), ("scream_4", lambda: scream(0, 0.86, 1.12, 0.7), 0.65),   # (três mulheres: nenhuma versão é a mesma voz no mesmo grito)
    ("megaphone", megaphone, None), ("whistle", lambda: whistle(0), 0.05), ("whistle_1", lambda: whistle(1), 0.05), ("door", door, 0.5),
    ("order", lambda: order(0), 0.5), ("order_1", lambda: order(1), 0.5), ("order_2", lambda: order(2), 0.5),
    ("plea", lambda: plea(0), 0.55), ("plea_1", lambda: plea(1), 0.55), ("baby", baby, 0.5),
    ("luggage", lambda: luggage(0), 0.5), ("luggage_1", lambda: luggage(1), 0.5), ("shutter", shutter, 0.5),
    ("rocket", rocket, None), ("rocket2", rocket, None),   # (o segundo da cena: outra semente, outros doze)
    ("rocket_far", far_rocket, None), ("rocket_far2", far_rocket, None),   # (os dois, de longe: mais tarde, depois da bandeira)
]


def scenes(made):
    """As três cenas montadas como o `Background` as toca (os instantes de `Beating.HITS`/`CRIES`, `Flyers.HONKS` e
    da viatura que para): só para ouvir, não vão para o jogo."""
    def db(x):
        return 10.0 ** (x / 20.0)
    beat = np.zeros(int(18.5 * RATE))
    nb.put(beat, made["commotion"], 0.9, db(-5))
    hits = [[11.3, 0], [11.9, 0], [12.5, 0], [13.5, 0], [14.05, 0], [14.6, 0], [15.6, 1], [16.6, 0], [17.15, 0], [18.1, 1], [18.9, 0], [19.45, 0]]
    for i, (at, kick) in enumerate(hits):
        nb.put(beat, made["kick" if kick else ("blow", "blow_1")[i % 2]], at - 8.0, db(-4))
        if i % 2 == 0:
            nb.put(beat, made[("groan", "groan_1", "groan_2")[(i // 2) % 3]], at - 8.0 + 0.05, db(-7))
    for at, name in ((8.7, "shout"), (11.6, "scream_1"), (13.1, "shout_2"), (14.6, "shout_1"), (16.0, "scream_4"), (17.6, "shout"),
            (19.9, "scream_2")):
        nb.put(beat, made[name], at - 8.0, db(-5 if name.startswith("scream") else -8))
    fly = np.zeros(int(11 * RATE))
    for at, name in ((0.6, "horn"), (2.6, "horn_1"), (4.3, "horn"), (6.0, "horn_2"), (8.2, "horn_1")):
        nb.put(fly, made[name], at, db(-6))
    lead, brake = 5.0, 3.2
    police = np.zeros(int(13 * RATE))
    far = made["siren_far"]
    k = int((lead + brake) * RATE)
    fade = np.ones(len(far))
    fade[int(lead * RATE):k] = np.linspace(1.0, 0.0, k - int(lead * RATE))
    fade[k:] = 0.0
    nb.put(police, far * fade, 0.0, db(-10))
    near = made["siren"][int((lead % SIREN["period"]) * RATE):][:int(brake * RATE)]
    nb.put(police, near * np.linspace(db(-14), 1.0, len(near)), lead, db(-3))
    hz, _, _ = wail_hz(2 * SIREN["period"])
    rate = hz[int(((lead % SIREN["period"]) + brake) * RATE)] / SIREN["down"]   # como o jogo: o som dela desligada na altura em que estava
    down = made["siren_down"]
    nb.put(police, np.interp(np.arange(0, len(down), rate), np.arange(len(down)), down), lead + brake, db(-3))
    chase = np.zeros(int(8.5 * RATE))   # (`Chase.SOUNDS`, de 4,5 s em diante)
    for at, name, g in ((5.0, "door", -2), (6.8, "whistle", -11), (9.6, "whistle_1", -11)):
        nb.put(chase, made[name], at - 4.5, db(g))
    raid = np.zeros(int(19 * RATE))   # (`Raid.SOUNDS`, a saída dos presos: de 45 s em diante)
    for at, name, g in ((46.5, "order", -3), (49.0, "plea", -9), (52.5, "order_2", -3), (55.0, "plea_1", -9), (58.0, "order_1", -3), (59.5, "whistle", -12)):
        nb.put(raid, made[name], at - 45.0, db(g))
    move = np.zeros(int(17 * RATE))   # (`Moving.sounds`: o bebê quando a família aparece e as malas na Kombi)
    nb.put(move, made["baby"], 0.5, db(-12))
    for at, name in ((9.2, "luggage"), (9.9, "luggage_1")):
        nb.put(move, made[name], at, db(-3))
    flag = np.zeros(int(7.3 * HI) + len(made["rocket2"]))   # (`Banner.ROCKETS`: um rojão 3 s antes de o pano descer, aqui aos 4,8 s, e o outro 3 s depois; na taxa deles)
    flag[int(1.8 * HI):int(1.8 * HI) + len(made["rocket"])] += made["rocket"]
    flag[int(7.3 * HI):] += made["rocket2"]
    return {"cena_bandeira": flag, "cena_espancamento": beat, "cena_panfletos": fly, "cena_viatura": police, "cena_corrida": chase, "cena_batida": raid, "cena_fuga": move}


if __name__ == "__main__":
    SAIDA.mkdir(parents=True, exist_ok=True)
    made = {}
    names = [name for name, _, _ in SOUNDS]
    for name, fn, far in SOUNDS:
        seed(300 + names.index(SEEDS.get(name, name)))
        x = fn()
        x = nb.norm(street(x, far) if far is not None else x, PEAK)
        rate = RATES.get(name, RATE)
        n = int(0.01 * rate)
        x[-n:] *= np.arange(n)[::-1] / n
        made[name] = x
        sf.write(SAIDA / (name + ".ogg"), x.astype(np.float32), rate, format="OGG", subtype="VORBIS")
        print(name, "%.2f s" % (len(x) / rate))
    f, start, top = wail_hz(1.0)
    print("sirene: começa o ciclo em %.0f Hz, no alto %.0f Hz" % (start, top))
    if len(sys.argv) > 1:
        made.update(scenes(made))
        for name, x in made.items():
            wavfile.write("%s/%s.wav" % (sys.argv[1], name), RATES.get(name, RATE), (nb.norm(x, 0.8) * 32767).astype(np.int16))
