# Docker Dev Setup

## Initial Setup

- Install Docker on your environment
- Clone the tacticalrmm and tacticalrmm-web directory next to eachother.
- Generate certs for nats
```bash
openssl req -nodes -new -x509 -keyout key.pem -out cert.pem -days 2000 -config san.cnf
```
## Run
Enter the docker-dev directory.
```bash
docker compose up
````

## Access

Access the web frontend at http://localhost:9000 and login with username dev 
and password dev. You will run through the initial MFA and Site setup.
