#!/bin/bash
# health-check.sh
# Checa a saúde de um servidor: serviço (systemd), porta (TCP) e resposta HTTP.
# Imprime OK ou FALHOU em cada checagem e termina com um código de saída:
#   0     = tudo certo
#   N > 0 = N checagens falharam (um pipeline usa isso pra ficar verde ou vermelho)
#
# Uso: ./health-check.sh

# A primeira linha (#!/bin/bash) diz ao sistema: "rode este arquivo com o bash".

# ---------------------------------------------------------------------------
# FUNÇÃO 1: checa se um serviço do systemd está ativo
# Uso: checa_servico docker
# ---------------------------------------------------------------------------
# Uma função é um bloco de código com nome. Definir não executa nada:
# só ensina o bash o que o nome significa. Por isso as funções vêm ANTES do uso.
checa_servico() {
    # $1 é o primeiro argumento passado na chamada.
    # Em "checa_servico docker", o $1 vale "docker".
    #
    # "systemctl is-active" responde pelo CÓDIGO DE SAÍDA:
    #   0 = ativo, diferente de 0 = não ativo.
    # O --quiet corta o texto "active" da tela, porque só o código interessa.
    # O "if" usa esse código: se for 0, entra no "then"; senão, vai pro "else".
    if systemctl is-active --quiet "$1"; then
        echo "OK      serviço $1"
    else
        echo "FALHOU  serviço $1"
        # "return 1" devolve o código 1 (falha) pra quem chamou a função.
        # É isso que o "||" lá embaixo detecta.
        return 1
    fi
}

# ---------------------------------------------------------------------------
# FUNÇÃO 2: checa se alguém está escutando numa porta TCP
# Uso: checa_porta 8080
# ---------------------------------------------------------------------------
checa_porta() {
    # "ss -tln" lista as portas TCP em escuta (t=TCP, l=listening, n=números).
    # O "|" (pipe) manda essa lista para o grep.
    # "grep -q" procura o texto sem imprimir nada (q=quiet) e só devolve
    # 0 se achou, ou diferente de 0 se não achou.
    # O padrão ":$1 " (dois pontos + número + espaço) evita confundir a porta
    # 80 com a 8080: sem o espaço no fim, ":80" também casaria com ":8080".
    if ss -tln | grep -q ":$1 "; then
        echo "OK      porta $1"
    else
        echo "FALHOU  porta $1"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# FUNÇÃO 3: checa se uma URL responde com HTTP 200
# Uso: checa_http http://localhost:8080
# ---------------------------------------------------------------------------
checa_http() {
    # $( ... ) roda o comando de dentro e guarda a SAÍDA na variável.
    # Aqui o curl não imprime nada na tela (-s silencioso, -o /dev/null joga
    # o corpo da página fora) e escreve só o código HTTP (-w "%{http_code}").
    # Esse código (200, 404, 500...) fica guardado na variável "codigo".
    # Se não conectar, o curl devolve 000.
    codigo=$(curl -s -o /dev/null -w "%{http_code}" "$1")

    # Compara o texto guardado com "200". Os colchetes [ ] são o "teste" do bash,
    # e precisam de espaço dentro e fora.
    if [ "$codigo" = "200" ]; then
        echo "OK      http $1 ($codigo)"
    else
        echo "FALHOU  http $1 ($codigo)"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# PROGRAMA PRINCIPAL: roda as checagens e conta quantas falharam
# ---------------------------------------------------------------------------
# Contador de falhas, começa em zero.
falhas=0

# "A || B" lê-se: "rode A; se A falhar, rode B".
# Quando uma função faz "return 1", o B roda e soma 1 em "falhas".
# $(( ... )) faz conta aritmética no bash.
checa_servico docker             || falhas=$((falhas + 1))
checa_porta 8080                 || falhas=$((falhas + 1))
checa_http http://localhost:8080 || falhas=$((falhas + 1))

# Resumo final.
echo "-----"
# -eq compara números (equal). Atenção: = compara texto, -eq compara número.
if [ "$falhas" -eq 0 ]; then
    echo "Tudo certo."
else
    echo "$falhas checagem(ns) falharam."
fi

# Devolve o número de falhas como código de saída do script inteiro:
# 0 se tudo passou, N se N checagens falharam.
exit "$falhas"
