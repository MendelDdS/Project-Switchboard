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
uniform float side = 1.5;                         // e para a direita, a poça esticada (`SIDE_LIGHT`)
uniform vec4 noir : source_color;                 // o escuro frio e a força dele (`NOIR`)
uniform float extra = 0.0;                        // o escuro a mais da luminária piscando ou ainda fria
uniform vec2 spot;                                // a luz da arandela do quadro de avisos: o meio dela (px)...
uniform vec2 spot_r = vec2(1.0);                  // ...até onde vai...
uniform float spot_k = 0.0;                       // ...e quanto do escuro ela tira (`BOARD_LIGHT`)
uniform vec4 daylight = vec4(1.0, 0.95, 0.85, 0.0);   // a luz do dia pela janela (cor, força; 0 de noite)...
uniform vec2 window_at;                           // ...vindo do meio dela (px)...
uniform float reach = 1000.0;                     // ...e chegando até essa distância

varying vec2 pos;

void vertex() {
	pos = VERTEX;   // px da tela (o `Background` desenha em 1x1 na tela dele)
}

void fragment() {
	vec2 q = (pos - center) / radius;
	q.x /= q.x > 0.0 ? side : 1.0;
	float k = smoothstep(inner, 1.0, length(q) / mix(1.0, front, smoothstep(0.0, 0.5, q.y)));
	float near = 1.0 - smoothstep(0.0, 1.0, distance(pos, window_at) / reach);
	float lit = 1.0 - spot_k * (1.0 - smoothstep(0.35, 1.0, length((pos - spot) / spot_r)));
	float a = clamp(noir.a * k + extra, 0.0, 0.9) * lit * (1.0 - daylight.a * mix(0.4, 1.0, near));   // o dia recua o escuro a partir da janela
	COLOR = vec4(noir.rgb, in_glass(pos) ? 0.0 : a);
}
