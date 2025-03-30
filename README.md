# Go Iris generator for JWT authentication config

BASH script to generate auth.yml config files with new certificates and keys for authentication using JWT.

## Requirements

- `openssl` - for generating certificates and keys
- `pwgen` - for generating hash and block keys

### Install dependencies

#### Debian/Ubuntu

**Install openssl and pwgen**

````bash
$ sudo apt update # always refresh cache before installing new packages
$ sudo apt install openssl pwgen
````

## Usage

**Add execution permission to script:** 

````bash
$ chmod +x generate.sh # make the script executable
````

**Usage example:**

````bash
$ ./generate.sh -a <Ed25519|secp384r1> [-c <config_file>] [-o <certs_output>]
````

**Arguments:**

* algorithm **-a** `required` : set keypairs encryption algorithm. Values accepted: **[Ed25519,secp384r1]**.
* output    **-o** *optional* : set JWT keypairs output directory.
* config    **-c** *optional* : set config filename.
* help      **-h** : display usage.

