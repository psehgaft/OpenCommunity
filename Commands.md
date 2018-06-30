# Comandos

## Git

* `git clone` : Copiar un repositorio desde una ubicacion remota
* `git fetch` : Obtener los cambios desde el remoto
* `git branch --list --all` : Obtener el listado de todas las ramas tanto locales como remotas
* `git status` : nos muetra informacion acerca del repositorio local
* `git diff --no-index $file1 $file2` : Comparar archivos
* `git pull origin $branch` : Obtener los datos que estan en el remoto  

## Bash

* `sed` : Editor de Streams
* `diff --color` : Comparar archivos
* `tar -czf $destino $origen` : Enpaquetar y comprimir archivos o directorios
* `tar -c $origen` : Enpaquetar archivos o directorios
* `xz -z $destino` : Comprimir archivos o directorios
* `dd` : Convertir y Copiar un archivo
* `tail $file` : Obtener la ultima parte de un archivo (default 10)
* `tail -n +2 $file`  :  Obtiene el archivo excepto la primera linea
* `sleep $time` : Un delay por cierto tiempo (segundos)
* `chage -d$tiempo $usuario` : Forzar a la expiracion del password
* `source $script` o `. $script` : Ejecuta un script en la instancia actual de bash
* `exec` : **TODO**
