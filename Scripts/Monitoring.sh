#!/bin/bash

VNUMBER_PROM_MAIN="2.22.1"
VERSION_PROM_MAIN="$VNUMBER_PROM_MAIN.linux-armv7"

VNUMBER_NODE_EXPR="1.0.1"
VERSION_NODE_EXPR="$VNUMBER_NODE_EXPR.linux-armv7"

VERSION_GRAFANA="7.3.2_armhf"

URL_PROM_MAIN="https://github.com/prometheus/prometheus/releases/download/v$VNUMBER_PROM_MAIN/prometheus-$VERSION_PROM_MAIN.tar.gz"
URL_NODE_EXPR="https://github.com/prometheus/node_exporter/releases/download/v$VNUMBER_NODE_EXPR/node_exporter-$VERSION_NODE_EXPR.tar.gz"

DEST_ROOT_DIR="/opt/monitoring"

DEST_PROM_MAIN="$DEST_ROOT_DIR/prometheus"
DEST_NODE_EXPR="$DEST_ROOT_DIR/node_exporter"

FOLDER_PROM_MAIN="$DEST_PROM_MAIN-$VERSION_PROM_MAIN"
FOLDER_NODE_EXPR="$DEST_NODE_EXPR-$VERSION_NODE_EXPR"

SERV_PROM="/etc/systemd/system/prometheus.service"
SERV_EXPR="/etc/systemd/system/node_exporter.service"

# ---- BAJAR y MOVER
sudo mkdir -p $DEST_ROOT_DIR
sudo chown -R javier:javier $DEST_ROOT_DIR

if [ -d $FOLDER_PROM_MAIN ]; then
	echo "Prometheus $VERSION_PROM_MAIN ya existe..."
else
	echo "Descargando Prometheus $VERSION_PROM_MAIN..."
	wget -O prometheus.tar.gz $URL_PROM_MAIN
	sudo rm -rf $DEST_PROM_MAIN
	sudo tar xfv prometheus.tar.gz --directory=$DEST_ROOT_DIR
	sudo ln -s $FOLDER_PROM_MAIN $DEST_PROM_MAIN
	sudo rm prometheus.tar.gz
fi

if [ -d $FOLDER_NODE_EXPR ]; then
	echo "Node Exporter $VERSION_NODE_EXPR ya existe..."
else
	echo "Descargando node Exporter $VERSION_NODE_EXPR..."
	wget -O node_exporter.tar.gz $URL_NODE_EXPR
	sudo rm -rf $DEST_NODE_EXPR
	sudo tar xfv node_exporter.tar.gz --directory=$DEST_ROOT_DIR
	sudo ln -s $FOLDER_NODE_EXPR $DEST_NODE_EXPR
	sudo rm node_exporter.tar.gz
fi
# Preparacion
sudo mkdir -p $DEST_PROM_MAIN/data
sudo chown -R javier $DEST_PROM_MAIN/data
sudo rm -f $DEST_PROM_MAIN/prometheus.yml
sudo cp prometheus.yml $DEST_PROM_MAIN/prometheus.yml
sudo chown -R javier:javier $DEST_PROM_MAIN/prometheus.yml
sudo chmod 755 $DEST_PROM_MAIN/prometheus.yml

# ---- CREAR EL SERVICIO DE NODE EXPORTER
if [ -f $SERV_EXPR ]; then
	echo "El servicio existe, no lo toco..."
else
#https://ask.xiaolee.net/questions/1008122
	echo "Creando el servicio..."
	sudo tee $SERV_EXPR <<- FINAAL > /dev/null
	[Unit]
	Description=Node Exporter
	After=network-online.target
	[Service]
	User=javier
	Restart=on-failure
	ExecStart=$DEST_NODE_EXPR/node_exporter --collector.textfile.directory $DEST_NODE_EXPR/textfile_collector
	[Install]
	WantedBy=multi-user.target
	FINAAL

	echo "CARGANDO DEMONIOS..."
	sudo systemctl daemon-reload
	echo "E INSTALANDO / ARRANCANDO EL SERVICIO..."
	sudo systemctl enable --now node_exporter
fi
	sudo systemctl restart node_exporter
# ---- CREAR EL SERVICIO DE PROMETHEUS
if [ -f $SERV_PROM ]; then
	echo "El servicio existe, no lo toco..."
else
	echo "Creando el servicio..."
	sudo tee $SERV_PROM <<- FINAAL > /dev/null
	[Unit]
	Description=Prometheus Server
	Documentation=https://prometheus.io/docs/introduction/overview/
	After=network-online.target
	[Service]
	User=javier
	Restart=on-failure
	ExecStart=$DEST_PROM_MAIN/prometheus --config.file=$DEST_PROM_MAIN/prometheus.yml --storage.tsdb.path=$DEST_PROM_MAIN/data
	[Install]
	WantedBy=multi-user.target
	FINAAL

	echo "CARGANDO DEMONIOS..."
	sudo systemctl daemon-reload
	echo "E INSTALANDO / ARRANCANDO EL SERVICIO..."
	sudo systemctl enable --now prometheus
fi
	sudo systemctl restart prometheus
# ---- GRAFANA + REQUERIMIENTOS
sudo apt-get install -y adduser libfontconfig1
# https://stackoverflow.com/questions/1298066/check-if-an-apt-get-package-is-installed-and-then-install-it-if-its-not-on-linu
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' grafana|grep "install ok installed")
if [ "" = "$PKG_OK" ]; then
	echo "Instalando grafana $VERSION_GRAFANA..."
	wget https://dl.grafana.com/oss/release/grafana_$VERSION_GRAFANA.deb
	sudo dpkg -i grafana_7.3.2_armhf.deb
	sudo rm -f grafana_7.3.2_armhf.deb
	sudo systemctl enable --now grafana-server
else
	echo "Grafana $VERSION_GRAFANA ya se encuentra instalado..."
fi
	sudo systemctl restart grafana-server
