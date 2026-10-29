extends Resource
## Gerador de códigos de autorização (a "interface"): o código de cada noite, que nunca se repete e segue um padrão
## que o jogador consegue deduzir. Usado pela B3 e por qualquer regra que precise (`Bureaucracy.codes`). Trocar o
## padrão: um script novo que estende este e sobrescreve `code`, posto em `data/bureaucracy/services/auth_codes.tres`;
## nada mais muda (validação, debug e regras só chamam `code`).


## O código da noite `night`; `index` separa vários códigos da mesma noite (0 = o do dia).
func code(_night: int, _index := 0) -> String:
	return ""
