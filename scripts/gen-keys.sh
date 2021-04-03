#!/bin/sh

NSSPIN="test123"
STOREPASS="test123"
CWD=$(pwd)
SHA="sha256"
RSA="rsa:2048"

init() {
    mkdir -p generated/keys
    mkdir -p generated/export
    rm -rf generated/keys/* generated/export/*
    cd generated/keys
}

print_cert() {
    keytool -printcert -v -file $1.der
}

init_nssdb() {
    mkdir -p ../export/$1/nssdb
    rm -rf ../export/$1/nssdb/*.db
    echo "$NSSPIN" > ../export/$1/nsspin.txt
    certutil -N -d dbm:../export/$1/nssdb -f ../export/$1/nsspin.txt
}

import_ca() {
    echo "importing ca cert $2.der into ../export/$1/nssdb"
    certutil -A -d dbm:../export/$1/nssdb -n "$2" -t "CT,C,C" -f ../export/$1/nsspin.txt -i $2.der
    echo "importing ca cert $2.crt into ../export/$1/truststore.jks"
    keytool -importcert -trustcacerts -noprompt -alias $2 -storetype JKS -storepass $STOREPASS -keystore ../export/$1/truststore.jks -file $2.der 
}

import_client() {
    echo "importing client keys $1.pfx into ../export/$1/nssdb"
    pk12util -d dbm:../export/$1/nssdb -k ../export/$1/nsspin.txt -w ../export/$1/nsspin.txt -i $1.pfx -n $1
    echo "importing client keys $1.pfx into ../export/$1/keystore.jks"
    keytool -importkeystore -noprompt -srcstoretype PKCS12 -srcstorepass $STOREPASS -deststorepass $STOREPASS -destkeystore ../export/$1/keystore.jks -srckeystore $1.pfx 
}

gen_p12() {
    # Create p12 file
    echo "creating p12 for $1 with $2.crts chain certs"
    openssl pkcs12 -export -out $1.pfx -inkey $1.key -in $1.crt -certfile $2.crts -password pass:"$NSSPIN" -name $1
}

copy_p12() {
    # Copy p12 file
    echo "copying p12 for $1"
    cp $1.pfx ../export/$1/keys.p12
}

gen_root() {
    # Generate self signed root CA cert
    openssl req -days 720 -$SHA -nodes -x509 -newkey $RSA -keyout $1.key -out $1.crt -extensions v3_ca -subj "/C=US/ST=CA/L=SFO/O=MC/OU=root/CN=root$1.admin/emailAddress=root$1@admin.com"

    # Create DER file
    openssl x509 -outform der -in $1.crt -out $1.der

    # Create CER file
    openssl x509 -outform pem -in $1.crt -out $1.cer

    cat $1.cer > $1.crts

    # Create PEM file
    cat $1.key $1.crt > $1.pem

    # Create p12 file
    openssl pkcs12 -export -out $1.pfx -inkey $1.key -in $1.crt -password pass:"$NSSPIN"
}

gen_signed() {
    # Generate cert to be signed
    openssl req -nodes -newkey $RSA -keyout $1.key -out $1.csr -subj "/C=US/ST=CA/L=SFO/O=MC/OU=root/CN=$1/emailAddress=$1@$2.com"

    # Sign the cert
    openssl x509 -req -days 720 -$SHA -in $1.csr -CA $3.crt -extfile ../../ssl.conf -extensions $4  -CAkey $3.key -CAcreateserial -out $1.crt -setalias "$1"

    # Create DER file
    openssl x509 -outform der -in $1.crt -out $1.der

    # Create CER file
    openssl x509 -outform pem -in $1.crt -out $1.cer

    # Create PEM file
    cat $1.key $1.crt > $1.pem

}

gen_intermediate() {
    gen_signed "$1" "admin" "ca" "v3_inter_ca"

    cat $1.cer $2.cer > $1.crts

    gen_p12 "$1" "$2"
}

gen_partner_intermediate() {
    gen_signed "$1ca" "$1" "$2" "v3_inter_ca"

    cat "$1ca.cer" $2.crts > "$1ca.crts"

    gen_p12 "$1ca" "$2"
}

gen_partner_client() {
    init_nssdb "$1"
    gen_signed "$1" "$2" "$2ca" "usr_cert"
    cat "$1.cer" "$2ca.crts" > "$1.crts"
    gen_p12 "$1" "$2ca"
    copy_p12 "$1"
    import_ca "$1" "ca"
    import_ca "$1" "interca"
    import_ca "$1" "$2ca"
    import_client "$1"
    echo "
name = NSScrypto-$1
nssSecmodDirectory = /opt/besu/p2p-ssl/nssdb
nssDbMode = readOnly
nssModule = keystore
    " >> ../export/$1/nss.cfg
}

init
gen_root "ca"
gen_intermediate "interca" "ca"

gen_partner_client "orion-dns-proxy" "interca"

gen_partner_intermediate "partnera" "interca"
gen_partner_client "partnera-firewall" "partnera"
gen_partner_client "validator1" "partnera"
gen_partner_client "validator2" "partnera"
gen_partner_client "rpcnode" "partnera"
gen_partner_client "explorer" "partnera"
gen_partner_client "member1besu" "partnera"
gen_partner_client "member1orion" "partnera"

gen_partner_intermediate "partnerb" "interca"
gen_partner_client "partnerb-firewall" "partnerb"
gen_partner_client "validator3" "partnerb"
gen_partner_client "member2besu" "partnerb"
gen_partner_client "member2orion" "partnerb"

gen_partner_intermediate "partnerc" "interca"
gen_partner_client "partnerc-firewall" "partnerc"
gen_partner_client "validator4" "partnerc"
gen_partner_client "member3besu" "partnerc"
gen_partner_client "member3orion" "partnerc"

print_cert "validator1"
