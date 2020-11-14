# Pasos que he seguido para ir dejando el sistema como me mola

1. Instalacion de *vim* y ponerlo por defecto con ```sudo update-alternatives --set editor /usr/bin/vim.basic```
1. Creacion del usuario de javier con ```adduser javier``` y meterlo al grupo de *sudo* con el ```usermod -aG sudo javier```
1. Copiar la clave publica en la carpeta ```/home/javier/.ssh``` [700], en el fichero ```authorized_keys``` [644]
1. Configurar el ssh para dejar acceder solo a este usuario y solo con pem [ver fichero adjunto]
1. Para el nopasswd, tocar dentro del ```/etc/sudoers.d```
  1. Hay un fichero ya para el usuario pi; al renombrarlo a algo con un ```.```, ya no lo lee
  1. Copiarlo para aplicarlo correctamente al usuario
1. Instalar el prometheus / grafana y demas [CON SCRIPT]
