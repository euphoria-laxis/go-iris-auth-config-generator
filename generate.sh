#!/bin/bash

# /*********************** IRIS AUTH CONFIG GENERATOR ***********************/
#   Config file generator for library github.com/kataras/iris/v12/auth.
#
#   Generate JWT certs, keys and block hashes. Certs are saved into directory 
#   "$output" by default, the config file is saved to auth.yml by default.
#   Authentication config use EdDSA, keypairs generated use ECC based algorithms 
#   like Ed25519 or secp384r1 for a reliable cryptographic security. 
#   /!\ Avoid RSA /!\ and be careful to ensure your application is secured as even
#   a strong encryption algorithm is no help if you don't use it correctly.
#
#   See usage example: https://github.com/kataras/iris/tree/main/_examples/auth/auth
#
#   Command usage:
#       -o  output      JWT keypairs output.
#                       default: certs/jwt
#       -c  config      Generated Iris auth configuration filenamee, should use yaml 
#                       or yml extension.
#                       default: auth.yml
#       -a  algorithm   Algorithm used to generated key pairs.
#                       valid values: [Ed25519, secp384r1]
#       -h  help        Display usage.
#

# Display command usage
usage () {
    echo "generate.sh: config file generator for library \"github.com/kataras/iris/v12/auth\"."
    echo "  See example: https://github.com/kataras/iris/tree/main/_examples/auth/auth"
    echo "  -o  output      (optional) JWT keypairs output. [certs/jwt]"
    echo "  -c  config      (optional) Config file, should use yaml or yml extension. [auth.yml]"
    echo "  -a  algorithm   Algorithm used to generated key pairs. valid values: [Ed25519, secp384r1]"
    echo "  -h  help        Display command usage."
    echo Bye!
    exit 0
}

# Parse arguments
while getopts ":o:c:a:h" option; do
    case "${option}" in
        o)
            output=${OPTARG}
            ;;
        c)
            config=${OPTARG}
            ;;
        a)
            alg=${OPTARG}
            # ensure $alg value is valid
            ((alg == "secp384r1" || alg == "Ed25519")) || usage
            ;;
        h)
            usage
            ;;
        :)
            echo "$OPTARG option require arguments"
            usage
            ;;
        \?)
            echo "$OPTARG : invalid option"
            usage
            ;;
    esac
done

# Set default values if arguments are empty
if [ -z "$output" ]; then # check $output
    output=certs/jwt
fi
if [ -z "$config" ]; then # check $config
    config=auth.yml
fi

# Generate keypairs and config
generate () {
    rm -rf "$output" # delete output directory if exists
    rm -f "$config" # delete config if exists
    mkdir -p "$output" # create output directory
    # Generate JWT keys
    openssl genpkey -algorithm "$alg" -out "$output"/access_token.pkey.pem
    if [ ! -f "$output"/access_token.pkey.pem ]; then
        echo Failed to generate "$output"/access_token.pkey.pem
        exit 73 # can't create output file
    fi
    openssl pkey -in "$output"/access_token.pkey.pem -pubout -out "$output"/access_token.pub.pem
    openssl genpkey -algorithm "$alg" -out "$output"/refresh_token.pkey.pem
    if [ ! -f "$output"/refresh_token.pkey.pem ]; then
        echo Failed to generate "$output"/refresh_token.pkey.pem
        exit 73 # can't create output file
    fi
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
        echo '    Hash: "'$(echo "$HASH_KEY")'" # length of 64 characters (512-bit).'
        echo '    Block: "'$(echo "$BLOCK_KEY")'" # length of 32 characters (256-bit).'
        echo 'Keys:'
        echo '    -   ID: IRIS_AUTH_ACCESS # required.'
        echo '        Alg: EdDSA'
        echo '        MaxAge: 2h # 2 hours lifetime for access tokens.'
        echo '        Private: |+'
    } > "$config"
    # keep indent in config for yaml format
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
}

# verify if $alg is set
if [ -z "$alg" ]; then # check $alg
    usage
    exit 64 # command line usage error
else
    generate
fi

