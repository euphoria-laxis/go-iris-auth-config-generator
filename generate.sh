#!/bin/bash

# /****************** IRIS AUTH CONFIG GENERATOR ******************/
# /* Generate JWT certs, keys and block hashes. Certs are saved into
#    directory "$output" by default, the config file is saved to
#    auth.yml by default.
#  */

while getopts ":o:c:" option; do
    case "${option}" in
        o)
            output=${OPTARG}
            ;;
        c)
            config=${OPTARG}
            ;;
        :)
            echo "$OPTARG option require arguments"
            usage
            exit 1
            ;;
        \?)
            echo "$OPTARG : invalid option"
            exit 1
            ;;
    esac
done

usage () {
    echo "o   output:       Output directory"
    echo "c   config:       Config file"
    echo Bye!
}

# Generate JWT keys
rm -rf "$output"
mkdir -p "$output"
openssl genpkey -algorithm ed25519 -out "$output"/access_token.pkey.pem
openssl pkey -in "$output"/access_token.pkey.pem -pubout -out "$output"/access_token.pub.pem
openssl genpkey -algorithm ed25519 -out "$output"/refresh_token.pkey.pem
openssl pkey -in "$output"/refresh_token.pkey.pem -pubout -out "$output"/refresh_token.pub.pem

# Generate hash and block keys
HASH_KEY=$(pwgen -1 64)
BLOCK_KEY=$(pwgen -1 32)

# Generate "$config" file
{
  echo 'Headers: # required.'
  echo '    - "Authorization"'
  echo '    - "X-Authorization"'
  echo 'Cookie: # optional.'
  echo '    Name: "_auth_cookie"'
  echo '    Secure: true'
  # shellcheck disable=SC2046
  # shellcheck disable=SC2116
  echo '    Hash: "'$(echo "$HASH_KEY")'" # length of 64 characters (512-bit).'
  # shellcheck disable=SC2046
  # shellcheck disable=SC2116
  echo '    Block: "'$(echo "$BLOCK_KEY")'" # length of 32 characters (256-bit).'
  echo 'Keys:'
  echo '    -   ID: IRIS_AUTH_ACCESS # required.'
  echo '        Alg: EdDSA'
  echo '        MaxAge: 2h # 2 hours lifetime for access tokens.'
  echo '        Private: |+'
} > "$config"
while read -r l; do
  echo "            $l" >> "$config"
done < "$output"/access_token.pkey.pem
echo '        Public: |+' >> "$config"
while read -r l; do
  echo "            $l" >> "$config"
done < "$output"/access_token.pub.pem
{
  echo '    -   ID: IRIS_AUTH_REFRESH # optional. Good practise to have it though.'
  echo '        Alg: EdDSA'
  echo '        # 1 month lifetime for refresh tokens'
  echo '        # after that period the user has to signin again.'
  echo '        MaxAge: 720h'
  echo '        Private: |+'
} >> "$config"
while read -r l; do
  echo "            $l" >> "$config"
done <"$output"/refresh_token.pkey.pem
echo '        Public: |+' >> "$config"
while read -r l; do
  echo "            $l" >> "$config"
done <"$output"/refresh_token.pub.pem
