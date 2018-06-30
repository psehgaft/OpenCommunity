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

    #Generacion de directorios

    mkdir -p $HOME_USUARIO/no_abrir_virus_peligroso_pero_compartido

    mkdir -p /compartidos/$ID_USUARIO

    ln -s /compartidos/$ID_USUARIO $HOME_USUARIO/compartido

    LISTA_GRUPOS=$(echo "$GRUPOS_RAW" | sed 's/,/ /g')

    ES_ALUMNO="N"
    ES_MAESTRO="N"

    for grupo in $LISTA_GRUPOS; do
        if [ "$grupo" == "maestro" ]; then
            mkdir -p $HOME_USUARIO/{juntas_academicas,asignaturas_especialidad,grupos/grupo_{a,b,c}}        
            ES_MAESTRO="Y"
        fi

        if [ "$grupo" == "estudiante" ]; then
            mkdir -p $HOME_USUARIO/{materias,calificaciones,trabajos/{trabajo_para_entregar,mis_trabajos,trabajo_final,trabajo_final_final,trabajo_final_este_es_el_bueno,trabajo_revisado}}
            ES_ALUMNO="Y"
        fi
    done
done
)
