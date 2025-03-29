#!/bin/bash

# Generate JWT keys
rm -rf certs/jwt
mkdir -p certs/jwt
openssl genpkey -algorithm ed25519 -out ./certs/jwt/access_token.pkey.pem
openssl pkey -in ./certs/jwt/access_token.pkey.pem -pubout -out ./certs/jwt/access_token.pub.pem
openssl genpkey -algorithm ed25519 -out ./certs/jwt/refresh_token.pkey.pem
openssl pkey -in ./certs/jwt/refresh_token.pkey.pem -pubout -out ./certs/jwt/refresh_token.pub.pem

# Generate hash and block keys
HASH_KEY=$(pwgen -1 64)
BLOCK_KEY=$(pwgen -1 32)

# Generate auth.yml file
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
} > auth.yml
while read -r l; do
  echo "            $l" >> auth.yml
done <./certs/jwt/access_token.pkey.pem
echo '        Public: |+' >> auth.yml
while read -r l; do
  echo "            $l" >> auth.yml
done <./certs/jwt/access_token.pub.pem
{
  echo '    -   ID: IRIS_AUTH_REFRESH # optional. Good practise to have it though.'
  echo '        Alg: EdDSA'
  echo '        # 1 month lifetime for refresh tokens'
  echo '        # after that period the user has to signin again.'
  echo '        MaxAge: 720h'
  echo '        Private: |+'
} >> auth.yml
while read -r l; do
  echo "            $l" >> auth.yml
done <./certs/jwt/refresh_token.pkey.pem
echo '        Public: |+' >> auth.yml
while read -r l; do
  echo "            $l" >> auth.yml
done <./certs/jwt/refresh_token.pub.pem
