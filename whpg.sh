# === Compilation

# Python
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
update-alternatives --install /usr/bin/python3 python /usr/bin/python3.12 1
update-alternatives --set python3 /usr/bin/python3.12
update-alternatives --set python /usr/bin/python3.12

export PYTHON='/usr/bin/python3.12'

dnf install -y epel-release
dnf update -y

dnf group install -y "Development Tools"

export PKG="apr-devel bison bzip2-devel cmake3 flex gcc gcc-c++ krb5-devel \
libcurl-devel libevent-devel libkadm5 libxml2-devel libzstd-devel \
openssl-devel python3.12 python3-devel python3.12-devel python3-psutil \
python3.12-pip perl-ExtUtils-MakeMaker.noarch perl-ExtUtils-Embed.noarch \
readline-devel rsync xerces-c-devel zlib-devel python3-psutil python3-pyyaml \
python3-psycopg2 perl perl-interpreter libyaml-devel libuuid-devel \
cyrus-sasl cyrus-sasl-devel openldap-devel postgresql postgresql-devel"

dnf install -y ${PKG} && dnf clean all


CFLAGS="-Wno-error -O2" CXXFLAGS="-std=c++17 -Wno-error" \
    ./configure --prefix=/usr/local/whpg

make

make install

tar cvf /tmp/whpg.tar /usr/local/whpg



# ==========================================================================================

podman network create net_whpg

SERVERS='masterdb sdw1 sdw2 sdw3 sdw4'

for i in ${SERVERS}; do

    podman container run -itd --name ${i} --hostname ${i}.edb -p 5432 \
        --network net_whpg almalinux:10

    podman container cp compiler:/tmp/whpg.tar.xz ${i}:/tmp/

    podman container cp /tmp/00_script.sh ${i}:/tmp/

    podman container exec -it ${i} chmod +x /tmp/00_script.sh

    podman container exec -it ${i} /tmp/00_script.sh

done






# /etc/hosts
cat << EOF >> /etc/hosts

#
master
sdw1
sdw2
sdw3

EOF



#
su - gpadmin

#
ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa

# 
cat << EOF > ~/.whpg_vars
# 
WHPG_HOME='/usr/local/whpg'

# Library directories
export LD_LIBRARY_PATH="\${WHPG_HOME}/lib:\${LD_LIBRARY_PATH}"

# Manuals directories
export MANPATH="\${WHPG_HOME}/man:\${MANPATH}"

# PostgreSQL data directory
export PGDATA='/var/local/whpg/data'

#
export PGPORT=5432

#
export PGUSER=gpadmin

#
export PGDATABASE=gpadmin

# Unset variables
unset WHPG_HOME PGBIN
EOF


# 
echo "source /usr/local/whpg/greenplum_path.sh" >> ~/.bash_profile
echo "source ~/.whpg_vars" >> ~/.bash_profile

# 
cat << EOF > ~/hostfile_gpinitsystem
sdw1
sdw2
sdw3
EOF

# 
cat << EOF > ~/gpinitsystem_config
# #####################################################################
# CONFIGURAÇÃO GERAL
# #####################################################################

# O nome do seu sistema de banco de dados (o nome do cluster).
ARRAY_NAME="whcluster_acme"

# O nome do banco de dados inicial a ser criado (geralmente 'postgres' ou 'template1').
DATABASE_NAME="${PGDATABASE}"

# A porta base para as instâncias de segmento.
# A porta do Master será BASE_PORT + 1. Os segmentos usarão as portas seguintes.
BASE_PORT=40000

# O ID do Master. Use 0 para sistemas de teste.
MASTER_ARRAY_HOST=0
MASTER_PORT=5432 # A porta do Master no seu host (pode ser a 5432 padrão ou outra)

# Prefixo para os diretórios de dados. Cada segmento terá um diretório
# com este prefixo seguido de um número. Ex: /data/gpseg0, /data/gpseg1
SEG_PREFIX=gpseg

# #####################################################################
# CONFIGURAÇÃO DE CAMINHOS
# #####################################################################

# Diretórios de dados do Master (coloque em um disco/volume persistente)
# Exemplo: /home/gpadmin/gpdata/master
MASTER_DIRECTORY=${PGDATA}

# Diretórios de dados dos Segmentos. Deve ser um caminho *existente* em cada host
# listado no hostfile. Para um VM, é um caminho único.
# ATENÇÃO: Se usar múltiplos segmentos virtuais, você precisará de múltiplos diretórios.
# Exemplo: DATA_DIRECTORY=/home/seu_usuario/gpdata/segmento1 /home/seu_usuario/gpdata/segmento2
# Se você tiver 4 segmentos no hostfile, precisará de 4 caminhos aqui.
DATA_DIRECTORY=/home/seu_usuario/gpdata/seg1 /home/seu_usuario/gpdata/seg2 /home/seu_usuario/gpdata/seg3 /home/seu_usuario/gpdata/seg4

# #####################################################################
# CONFIGURAÇÃO DE REDE (Recomendado para ambientes de teste)
# #####################################################################

# Tamanho do segmento (o número de segmentos primários no seu cluster).
# Deve ser igual ao número de linhas no seu hostfile_gpinitsystem.
MACHINE_SEGMENTS=3 # (Neste exemplo, assumindo 4 linhas no hostfile)
EOF
















