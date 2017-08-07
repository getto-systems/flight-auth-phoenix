# flight-auth-phoenix

auth module for getto/flight using phoenix.socket

# run

```
docker run getto/flight-auth-phoenix:[VERSION] flight_auth sign <auth_key> --file data.json
docker run getto/flight-auth-phoenix:[VERSION] flight_auth verify <auth_key> --expire 3600 --token <token>
```

# pull

```
docker pull getto/flight-auth-phoenix
```

# build

```
docker build -t getto/flight-auth-phoenix dockerfile
```
