#!/bin/bash

# Es importante eliminar los caracteres de retorno de carro (\r - 0x0D) (MICROSOOOOFT!!!!!!)  o serán agregados a las 
# variables y causarán problemas en las impresiones de pantalla y probablemente los demás comandos
# Por supuesto, este script no está diseñado para funcionar con archivos con cambios de línea estilo MacOS
sed 's/\r//g' | (
while IFS=$'\t' read NOMBRE ID_USUARIO GRUPOS_RAW; do

    echo "-Generando ambiente para: Nombre:" $NOMBRE "ID:" $ID_USUARIO "Grupos:" $GRUPOS_RAW

    GRUPO_PRINCIPAL=$(echo $GRUPOS_RAW | cut -d"," -f1)
    GRUPOS_SECUNDARIOS=$(echo $GRUPOS_RAW | cut -d"," -f2-)
    ARGUMENTO_GRUPOS_SECUNDARIOS=""
    HOME_USUARIO=/home/$ID_USUARIO

    if [ -n "$GRUPOS_SECUNDARIOS" ]; then
        ARGUMENTO_GRUPOS_SECUNDARIOS="-G$GRUPOS_SECUNDARIOS"
    fi

    # $1$OPENCOM$ZNFxZz0M5slIwRlIOQRH9/ = 'changeme'
    # Es posible utilizar un password blanco, pero es necesatio cambiar la opción 'PermitEmptyPasswords' del servidor SSH 
    useradd -g$GRUPO_PRINCIPAL $ARGUMENTO_GRUPOS_SECUNDARIOS -d $HOME_USUARIO -c"$NOMBRE" -p '$1$OPENCOM$ZNFxZz0M5slIwRlIOQRH9/' $ID_USUARIO

    #Cambiar password en el primer login
    chage -d0 $ID_USUARIO

done
)
