shader_type canvas_item;
// O escuro da sala (noir, plano hi-bit, etapa 5): tudo o que a luz da luminária não alcança fica frio e escuro, liso,
// crescendo da poça de luz na mesa para fora numa elipse larga, mais longe para a frente da mesa. Na camada
// `_noir` do `Background`, no lugar do antigo `_draw_gloom` (o reflexo da janela, o embaçado e o relâmpago continuam
// por cima); a luminária piscando ou esquentando só muda `extra`, sem redesenhar nada (`Background._noir_params`).
#include "res://scripts/ui/glass.gdshaderinc"

uniform vec2 center;                              // o meio da poça de luz na mesa (px)
uniform vec2 radius = vec2(615.0, 248.0);         // até onde a luz vai antes do escuro todo (`GLOOM_R`)
uniform float inner = 0.25;                       // dentro dessa fração do raio, nada de escuro (`GLOOM_IN`)
uniform float front = 1.6;                        // para a frente da mesa a luz vai essa vez mais longe (`FRONT_LIGHT`)
uniform vec4 noir : source_color;                 // o escuro frio e a força dele (`NOIR`)
uniform float extra = 0.0;                        // o escuro a mais da luminária piscando ou ainda fria
uniform vec4 daylight = vec4(1.0, 0.95, 0.85, 0.0);   // a luz do dia pela janela (cor, força): a etapa 7; 0 por ora

varying vec2 pos;

void vertex() {
	pos = VERTEX;   // px da tela (o `Background` desenha em 1x1 na tela dele)
}

void fragment() {
	vec2 q = (pos - center) / radius;
	float k = smoothstep(inner, 1.0, length(q) / mix(1.0, front, smoothstep(0.0, 0.5, q.y)));
	float a = clamp(noir.a * k + extra, 0.0, 0.9) * (1.0 - daylight.a);   // o dia recua o escuro
	COLOR = vec4(noir.rgb, in_glass(pos) ? 0.0 : a);
}
