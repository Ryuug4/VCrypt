#!/bin/bash
figlet -k VCrypt-RTHA | lolcat 

fortune | lolcat  

echo Developed By Inzu-RTHA

# Check if an image file has been provided as an argument
if [ -z "$1" ]; then
  echo "Please provide an image file as an argument."
  exit 1
fi

# Define the encryption algorithm
encrypt() {
  image=$1
  width=$(identify -format "%w" $image)
  height=$(identify -format "%h" $image)
  size=$((width * height))

  # Generate two random binary keys
  key1=$(openssl rand -hex $size | tr -d '\n')
  key2=$(openssl rand -hex $size | tr -d '\n')

  # Create two blank images with the same size as the original image
  convert -size ${width}x${height} xc:white key1.png
  convert -size ${width}x${height} xc:white key2.png

  # For each pixel in the original image, if the pixel is black, assign a random value from key1 to key1.png, and assign the inverse of the same value from key2 to key2.png
  for (( i=0; i<$size; i++ )); do
    color=$(convert $image -depth 8 -crop 1x1+$(($i%$width))+$(($i/$width)) txt: | tail -n 1 | awk '{print $3}')
    if [ "$color" == "black" ]; then
      key1_value=$(echo $key1 | cut -c $(($i+1)))
      key2_value=$((1-$key1_value))
      convert key1.png -fill "gray($(($key1_value*100)))" -draw "point $(($i%$width)),$(($i/$width))" key1.png
      convert key2.png -fill "gray($(($key2_value*100)))" -draw "point $(($i%$width)),$(($i/$width))" key2.png
    fi
  done

  # Combine the two keys to generate the encrypted image
  convert key1.png key2.png -combine encrypted.png

  # Clean up temporary files
  rm key1.png key2.png

  echo "Encryption completed. The encrypted image is stored in encrypted.png."
}

# Define the decryption algorithm
decrypt() {
  image=$1

  # Split the encrypted image into two keys
  convert $image -channel R -separate key1.png
  convert $image -channel G -separate key2.png

  # Combine the two keys to generate the original image
  convert key1.png key2.png -combine decrypted.png

  # Clean up temporary files
  rm key1.png key2.png

  echo "Decryption completed. The original image is stored in decrypted.png."
}

# Check the command line arguments and execute the appropriate function
if [ "$2" == "encrypt" ]; then
  encrypt $1
elif [ "$2" == "decrypt" ]; then
  decrypt $1
else
  echo "Usage: vcrypt.sh <image file> [encrypt|decrypt]"
fi
