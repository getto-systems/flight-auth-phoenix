# flight-auth-phoenix

auth module for getto/flight using phoenix.socket

# usage

## sign

```
docker run getto/flight-auth-phoenix flight_auth sign <auth_key> --file data.json

# data.json
{"role": <role>}
```

## verify

```
docker run getto/flight-auth-phoenix flight_auth verify <auth_key> --expire 3600 --token <token>
# => <role>
```

# pull

```
docker pull getto/flight-auth-phoenix
```

# build

```
docker build -t getto/flight-auth-phoenix .
```
