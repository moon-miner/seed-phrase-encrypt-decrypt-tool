#!/bin/bash
# usage

if [[ $# -lt 1 ]]; then
    echo ""
    echo "      Prerequisites: coreutils openssl qrencode zbar-tools"
    echo "      Install prerequisites (debian): $0 install"
    echo "      Usage:"
    echo "              $0 [Args] [enc|dec] ['seed phrase'|qr_file|encrypted seed text]"
    echo ""
    echo "      Args:"
    echo "              -p 'password' | If not present script uses default password¨ 'mypass'"
    echo "              -o 'output_QR_filename' | If not present script uses default file name 'QR coded seed'"
    echo ""
    echo "      Examples:"
    echo "                  $0 enc 'seed phrase' | encrypt seed with default password and output QR image with default file name"
    echo "                  $0 -p 'example password' -o 'example_filename' enc 'seed phrase' | encrypt seed with password 'example password' and output file 'example_filename.png´"
    echo "                  $0 dec 'encrypted seed text' | script decrypt using default pasowrd"
    echo "                  $0 -p asd123 dec 'encrypted seed text' | decrypt using password asd123"
    echo "                  $0 -p asd123 dec 'my qr code.png' | scans file 'my qr code.png' and decrypt using password asd123"
    echo ""
    echo ""
    echo "                                  000000000           "
    echo "                              000000000000000000      "
    echo "                            000000          000000    "
    echo "                           000                  000   "
    echo "                          000     0000000000     000  "
    echo "                         000      0000000000      000 "
    echo "                         00        0000           000 "
    echo "                        000          0000          000"
    echo "                        000          0000          000"
    echo "                         000       0000            00 "
    echo "                         000      0000000000      000 "
    echo "                          000     0000000000     000  "
    echo "                           000                  000   "
    echo "                            000000          000000    "
    echo "                              000000000000000000      "
    echo "                                   000000000          "
    echo ""
    echo ""
    exit 1
fi

# Valores predeterminados
password="mypass"
archivo_salida="QR coded seed"
accion=""
entrada=""

# Función para encriptar y generar un QR
encriptar_y_generar_qr() {
    texto=$1
    archivo=$2
    # Encriptar el texto
    encriptado=$(echo "$texto" | openssl enc -aes-256-cbc -a -salt -pbkdf2 -iter 10000 -pass pass:"$password")

    # Mostrar el texto encriptado en consola
    echo "encrypted seed: $encriptado"

    # Si se proporciona un archivo de salida, generar el archivo QR
    if [[ -n "$archivo" ]]; then
        echo "$encriptado" | qrencode -o "${archivo}.png" -c
        echo "QR file generated: ${archivo}.png"
    fi
}

# Función para desencriptar un texto
desencriptar_texto() {
    texto=$1
    desencriptado=$(echo "$texto" | openssl enc -aes-256-cbc -a -d -salt -pbkdf2 -iter 10000 -pass pass:"$password")
    echo "Seed phrase: $desencriptado"
}

# Procesar los argumentos
while getopts "p:o:" opt; do
    case $opt in
        p)
            password="$OPTARG"  # Asigna el valor de la opción -p
            ;;
        o)
            archivo_salida="$OPTARG"  # Asigna el valor de la opción -o
            ;;
        *)
            echo "Uso inválido. Usa -p para password y -o para el nombre de archivo de salida."
            exit 1
            ;;
    esac
done

# El resto de los argumentos después de las opciones (acción y entrada)
shift $((OPTIND - 1))
accion=$1
entrada=$2

# Ejecuta la acción
case $accion in
    install)
        # Actualiza los repositorios
        sudo apt update
        # Instala los paquetes necesarios
        sudo apt install -y coreutils openssl qrencode zbar-tools
        ;;
    enc)
        if [[ -f "$entrada" ]]; then
            # Si la entrada es un archivo QR, leerlo y extraer el texto
            texto=$(zbarimg "$entrada" | sed 's/^QR-Code://')
            desencriptar_texto "$texto"
        elif [[ -n "$entrada" ]]; then
            # Si la entrada es texto, encriptarlo y generar un QR
            encriptar_y_generar_qr "$entrada" "$archivo_salida"
        else
            echo "Error: Ingrese un texto o archivo QR válido."
            exit 1
        fi
        ;;
    dec)
        if [[ -f "$entrada" ]]; then
            # Si la entrada es un archivo QR, leerlo y extraer el texto
            texto=$(zbarimg "$entrada" | sed 's/^QR-Code://')
            desencriptar_texto "$texto"
        elif [[ -n "$entrada" ]]; then
            # Si la entrada es texto encriptado, desencriptarlo
            desencriptar_texto "$entrada"
        else
            echo "Error: Ingrese un texto encriptado o archivo QR válido."
            exit 1
        fi
        ;;
    *)
        echo "invalid use: use [arguments] 'enc' o 'dec' "
        exit 1
        ;;
esac
