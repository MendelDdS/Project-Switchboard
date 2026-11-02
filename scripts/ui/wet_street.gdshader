shader_type canvas_item;
// A rua molhada (a camada `_wet` do `Background`, `_draw_wet_street`). Duas coisas, pela cor do que é desenhado:
// - o chão, em preto: o asfalto espelha o que já está desenhado embaixo da camada (as fachadas de lá, as janelas e
//   vitrines acesas, a porta do hotel), virado no pé das fachadas (`axis`). No asfalto, áspero, o reflexo estica para
//   baixo (`stretch`) e borra um pouco para cima e é cortado por quebras finas na horizontal; nas poças, quase um espelho, e a água mais
//   escura, com os pingos abrindo anéis; no asfalto, os respingos acendem um pixel e somem, mais vistos no reflexo
//   claro. Poças, anéis e respingos crescem com a força da chuva (`rain`, `t`). Só a luz reflete (o escuro das paredes
//   some). A calçada de lá (até `curb_top`) reflete quase inteira, cortada pelas juntas das
//   lajotas; na face do meio-fio (até `curb`) o reflexo quebra, e na rua, um degrau abaixo da calçada, desce `drop`.
//   O chão de cada carro tapa o espelho atrás dele (`cars`). O relâmpago (`flash`) acende o céu espelhado, mais nas poças;
// - o risco de uma luz que fica na frente da fachada (postes, letreiro, faróis), na cor dos vértices: o brilho falha
//   nas manchas mais secas do asfalto e fica inteiro nas poças.
// Cada pixel lê pixels inteiros do que está embaixo (nada de esticar a pixel art pela transformação).

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float axis = 0.0;      // o pé das fachadas de lá (y, px da vista): o espelho
uniform float reach = 100.0;   // até onde, abaixo dele, o espelho vai sumindo (px)
uniform float wet = 1.0;       // a força (a chuva, 1; o sereno da manhã, menos)
uniform float stretch = 0.5;   // no asfalto, o pixel a d do espelho mostra o que está a d·stretch acima dele
uniform float rain = 1.0;      // a força da chuva (`rain_level`; 0: o sereno da manhã, que só umedece): poças, anéis, respingos
uniform float flash = 0.0;     // o clarão do relâmpago agora (`_flash`)
uniform float curb_top = 0.0;  // a quina do meio-fio de lá (y, px): acima, a calçada, mais lisa, cortada pelas juntas...
uniform float curb = 0.0;      // ...o pé dele: entre os dois, a face, que não reflete...
uniform float drop = 1.0;      // ...e, abaixo dela, o espelho desce tanto (px: a rua mais baixa que a calçada)
uniform vec2 glare = vec2(0.08, 0.45);   // o claro a partir do qual o que está embaixo começa a refletir e reflete inteiro (de manhã, mais alto: só as vitrines)
uniform float t = 0.0;         // s (`PixelArt.ms`)
uniform vec4 cars[8];          // o que cada carro tapa: de x, até x, de y, até y (px; vazio: zeros)
uniform float horizon = 0.0;   // a câmera da vista (`_o`), para pôr o grão e as poças no chão de verdade: o horizonte (px),...
uniform float ox = 0.0;        // ...o ponto de fuga (x, px),...
uniform float fe = 364.8;      // ...a focal vezes a altura dos olhos (px·m)...
uniform float f2 = 96.0;       // ...e a focal (px)
uniform float seam = 9.0;      // a junta das lajotas ao longo da calçada de lá (m; as outras de `SLAB` em `SLAB`, a partir de -30)
const float SLAB = 1.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// O ponto do chão (m: x ao longo da rua, z de distância) no pixel `p` da vista.
vec2 ground(vec2 p) {
	float z = fe / max(p.y - horizon, 0.5);
	return vec2((p.x - ox) * z / f2, z);
}

// A faixa do asfalto a `d` px do espelho: faixas de 3 px junto dele, mais largas para perto de nós (a perspectiva).
float band(float d) {
	return floor(log(1.0 + 0.025 * max(d, 0.0)) / 0.075);
}

void fragment() {
	vec2 here = floor(SCREEN_UV / SCREEN_PIXEL_SIZE) + 0.5;
	bool road = here.y > curb;
	bool walk = here.y < curb_top;
	float d = here.y - axis - (road ? drop : 0.0);   // px abaixo do espelho (o da rua, mais baixo)
	vec2 w = ground(here);
	// as poças, no chão da rua (não na calçada), de beira seca
	float pud = road && rain > 0.0 ? step(0.72 - 0.08 * rain, noise(w / vec2(2.6, 1.6)) * 0.8 + noise(w / vec2(0.7, 0.45)) * 0.2) : 0.0;
	// o asfalto: o reflexo inteiro, cortado por quebras de um pixel na horizontal, no começo de algumas faixas e em
	// trechos (mais compridos para perto de nós); nunca deslocado para o lado (deslocado, parece água)
	float b = band(d);
	float run = 8.0 + d * 0.3;
	bool gap = b != band(d - 1.0) && hash(vec2(b, floor((here.x + hash(vec2(b, 3.0)) * 60.0) / run))) < 0.6;
	float grain = gap ? 0.3 : 1.0;
	if (walk) {   // a calçada, mais lisa: o reflexo quase inteiro, cortado pelas juntas das lajotas (um pixel escuro)
		vec2 wl = ground(here - vec2(1.0, 0.0));
		vec2 wu = ground(here - vec2(0.0, 1.0));
		bool joint = floor((w.x + 30.0) / SLAB) != floor((wl.x + 30.0) / SLAB) || (w.y - seam) * (wu.y - seam) <= 0.0;
		grain = joint ? 0.15 : 0.85;
	}
	if (dot(COLOR.rgb, vec3(1.0)) > 0.001) {   // o risco de uma luz
		COLOR.a *= mix(grain, 1.4, pud);
	} else {   // o chão: o espelho
		vec3 base = texture(screen, SCREEN_UV).rgb;
		float ring = 0.0;   // o anel de um pingo por célula, abrindo e sumindo, achatado pela perspectiva
		if (pud > 0.0) {
			vec2 cell = vec2(12.0, 5.0);
			vec2 c = floor(vec2(here.x, d) / cell);
			float ph = fract(t * 0.7 + hash(c));
			ph = hash(c + 29.0) < rain ? ph : 1.0;   // (na garoa, poucos)
			vec2 dv = vec2(here.x, d) - (c + 0.2 + 0.6 * vec2(hash(c + 7.0), hash(c + 13.0))) * cell;
			dv.y *= 2.5;
			ring = (1.0 - smoothstep(0.2, 0.8, abs(length(dv) - 0.5 - ph * 4.0))) * (1.0 - ph) * pud;
		}
		float s = mix(stretch, 1.0, pud);
		float blur = mix(1.0 + d * 0.3, 0.0, pud);
		vec3 acc = vec3(0.0);
		for (int i = 0; i < 8; i++) {
			float sy = floor(axis - d * s - blur * float(i) / 7.0) + 0.5;
			acc += texture(screen, vec2(here.x + round(ring), sy) * SCREEN_PIXEL_SIZE).rgb;
		}
		acc /= 8.0;
		vec3 lit = acc * smoothstep(glare.x, glare.y, dot(acc, vec3(0.299, 0.587, 0.114)));
		for (int i = 0; i < 8; i++) {
			vec4 b = cars[i];
			if (here.x > b.x && here.x < b.y && here.y > b.z && here.y < b.w) {
				lit = vec3(0.0);
			}
		}
		float fall = 1.0 - smoothstep(0.0, reach, d);
		lit += vec3(0.8, 0.85, 0.95) * flash * mix(0.35, 1.0, pud);   // o céu do relâmpago, espelhado
		float k = wet * fall * mix(0.7 * grain, 1.0, pud);
		if (!road && !walk) {
			k = 0.0;   // a face do meio-fio
		}
		float splash = 0.0;   // um respingo por célula, de vez em quando, num pixel dela (e meio no do lado)
		if (rain > 0.0 && pud < 0.5 && road) {
			vec2 cell = vec2(7.0, 3.0);
			vec2 c = floor(vec2(here.x, d) / cell);
			vec2 at = floor(c * cell + vec2(hash(c + 3.0) * cell.x, hash(c + 5.0) * cell.y));
			float on = step(fract(t * 1.1 + hash(c) * 9.0), 0.08) * step(hash(c + 11.0), rain * 0.7);
			vec2 off = floor(vec2(here.x, d)) - at;
			splash = on * (off == vec2(0.0) ? 1.0 : (off == vec2(1.0, 0.0) ? 0.4 : 0.0));
		}
		COLOR = vec4(base * (1.0 - 0.35 * pud * wet) + lit * k + (0.1 * ring + splash * 0.1) * wet + splash * lit * 0.5 * fall, 1.0);
	}
}
