// O vidro da janela abaixo da persiana (`Background._glass`, px da tela, convexo, até 8 cantos): a luz da sala não
// passa nele (a rua tem a luz dela). Usado pelos shaders da luz da luminária.
uniform vec2 glass[8];
uniform int glass_n = 0;   // quantos cantos ele tem (0: persiana fechada)

bool in_glass(vec2 p) {   // dentro do polígono convexo: do mesmo lado de todas as beiras
	if (glass_n < 3) {
		return false;
	}
	bool pos = false;
	bool neg = false;
	for (int i = 0; i < glass_n; i++) {
		vec2 a = glass[i];
		vec2 b = glass[(i + 1) % glass_n];
		float s = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
		pos = pos || s > 0.0;
		neg = neg || s < 0.0;
	}
	return !(pos && neg);
}
