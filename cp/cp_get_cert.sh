#/usr/bin/bash
echo "Fetches Certsecho Fetching Docker certs  to fix x509: certificate signed by unknown authority ERROR"
update-ca-certificates --fresh
openssl s_client -showcerts -verify 5 -connect registry-1.docker.io:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/docker.crt
openssl s_client -showcerts -verify 5 -connect docker.io:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/docker-io.crt
openssl s_client -showcerts -verify 5 -connect production.cloudflare.docker.com:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/docker-com.crt
openssl s_client -showcerts -verify 5 -connect *.docker.com:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/docker-com2.crt
cp ~/docker*.crt /usr/local/share/ca-certificates/
c_rehash /etc/ssl/certs/
update-ca-certificates
echo "\nNOTE: >>>>> Restart Docker to accept new Certs <<<<<"
