# health-check

Script em Bash que checa a saúde de um servidor Linux e devolve um código de saída que pipelines conseguem usar. Projeto de estudo de Linux e automação, em transição para DevOps.

## O que ele checa
| Checagem | Como | Exemplo no script |
|---|---|---|
| **Serviço** | `systemctl is-active`: o serviço do systemd está ativo? | `docker` |
| **Porta** | `ss -tln`: alguém escuta nessa porta TCP? | `8080` |
| **HTTP** | `curl`: a URL responde com código 200? | `http://localhost:8080` |

Cada checagem imprime `OK` ou `FALHOU`:
```
OK      serviço docker
OK      porta 8080
OK      http http://localhost:8080 (200)
-----
Tudo certo.
```

## Código de saída
| Código | Significado |
|---|---|
| `0` | Tudo certo |
| `N` (maior que 0) | N checagens falharam |

É esse código que um pipeline de CI/CD usa para ficar verde ou vermelho:
```bash
./health-check.sh && echo "pode seguir" || echo "parar aqui"
```

## Como usar
Requisitos: Linux com systemd e os comandos `systemctl`, `ss` e `curl`.

```bash
chmod +x health-check.sh
./health-check.sh
echo $?        # mostra o código de saída
```

Para checar outros alvos, edite as três linhas de chamada no fim do arquivo:
```bash
checa_servico docker             || falhas=$((falhas + 1))
checa_porta 8080                 || falhas=$((falhas + 1))
checa_http http://localhost:8080 || falhas=$((falhas + 1))
```

## Exemplo de falha
Com o site parado (porta 8080 sem ninguém escutando):
```
OK      serviço docker
FALHOU  porta 8080
FALHOU  http http://localhost:8080 (000)
-----
2 checagem(ns) falharam.
```
O código de saída desse caso é `2`. O HTTP `000` quer dizer que o `curl` nem conseguiu conectar.

## O que demonstra
- Funções em Bash com argumento (`$1`) e retorno (`return 1`).
- Código de saída como forma de comunicação entre programas.
- Diagnóstico em camadas: serviço, depois porta, depois resposta da aplicação.
- Contagem de falhas com `||` e aritmética (`$(( ))`).

## Estrutura
| Arquivo | Função |
|---|---|
| `health-check.sh` | O script, comentado passo a passo |
| `README.md` | Este arquivo |

## Autor
Eduardo Sena Santos Gomes · estudante de ADS · em transição para DevOps.
