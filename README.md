# Go Iris generator for JWT authentication config

BASH script to generate auth.yml config files with new certificates and keys for authentication using JWT.

## Requirements

- `openssl` - for generating certificates and keys
- `pwgen` - for generating hash and block keys

### Install dependencies

#### Debian/Ubuntu

````bash
$ sudo apt update # always refresh cache before installing new packages
$ sudo apt install openssl pwgen
````

## Usage

````bash
$ chmod +x generate.sh # make the script executable
$ ./generate.sh
````
