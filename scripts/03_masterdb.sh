#!/bin/bash

# Read environment variables file
source ~/.whpg_vars

# Cluster initial configuration ----------------------------------------------

# Segment hosts file
cat << EOF > ~gpadmin/hostfile_gpinitsystem
sdw1
sdw2
sdw3
EOF

# 
mkdir -p ${MASTER_DIRECTORY} ${DATA_DIRECTORY}

# Initialization configuration file for WarehousePG
cat << EOF > ~gpadmin/gpinitsystem_config
# #####################################################################
# CONFIGURAÇÃO GERAL
# #####################################################################

# O nome do seu sistema de banco de dados (o nome do cluster).
ARRAY_NAME="whcluster_acme"

# O nome do banco de dados inicial a ser criado (geralmente 'postgres' ou 'template1').
DATABASE_NAME='${PGDATABASE}'

COORDINATOR_HOSTNAME="`hostname -s`"

# A porta base para as instâncias de segmento.
# A porta do Master será BASE_PORT + 1. Os segmentos usarão as portas seguintes.
PORT_BASE=40000

# O ID do Master. Use 0 para sistemas de teste.
MASTER_ARRAY_HOST=0
MASTER_PORT='${PGPORT}' # A porta do Master no seu host (pode ser a 5432 padrão ou outra)

# Prefixo para os diretórios de dados. Cada segmento terá um diretório
# com este prefixo seguido de um número. Ex: /data/gpseg0, /data/gpseg1
SEG_PREFIX=gpseg

# #####################################################################
# CONFIGURAÇÃO DE CAMINHOS
# #####################################################################

# Diretórios de dados do Master (coloque em um disco/volume persistente)
# Exemplo: /home/gpadmin/gpdata/master
MASTER_DIRECTORY='${MASTER_DIRECTORY}'

# Diretórios de dados dos Segmentos. Deve ser um caminho *existente* em cada host
# listado no hostfile. Para um VM, é um caminho único.
# ATENÇÃO: Se usar múltiplos segmentos virtuais, você precisará de múltiplos diretórios.
# Exemplo: DATA_DIRECTORY=/home/seu_usuario/gpdata/segmento1 /home/seu_usuario/gpdata/segmento2
# Se você tiver 4 segmentos no hostfile, precisará de 4 caminhos aqui.
DATA_DIRECTORY='${DATA_DIRECTORY}'

# #####################################################################
# CONFIGURAÇÃO DE REDE (Recomendado para ambientes de teste)
# #####################################################################

# Tamanho do segmento (o número de segmentos primários no seu cluster).
# Deve ser igual ao número de linhas no seu hostfile_gpinitsystem.
MACHINE_SEGMENTS=3 # (Neste exemplo, assumindo 4 linhas no hostfile)
EOF

chown -R gpadmin: ~gpadmin

