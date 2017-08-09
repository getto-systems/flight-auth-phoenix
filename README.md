# flight-auth-phoenix

auth module for getto/flight using phoenix.socket

# usage

## password-hash

filter data for update user profile

```
echo $data
# => {"password": <password>}

docker run \
  -e FLIGHT_DATA="$data" \
  getto/flight-auth-phoenix \
  flight_auth password-hash <salt> [--password password]

# => {"password": <hashed password>}
```

## format-for-auth

filter query for authorize

```
echo $data
# => {"key": <key>, "password": <password>}

docker run \
  -e FLIGHT_DATA="$data" \
  getto/flight-auth-phoenix \
  flight_auth format-for-auth <salt> [--password password] [--role role]

# => {"key": <key>, "conditions": {"password": <hashed password>}, columns: ["role"]}
```

## sign

```
echo $data
# => {"role": <role>}

docker run \
  -e FLIGHT_DATA="$data" \
  getto/flight-auth-phoenix \
  flight_auth sign <auth_key>

# => {"role": <role>, "token": <token>}
```

## verify

```
echo $data
# => {"token": <token>}

docker run \
  -e FLIGHT_DATA="$data" \
  getto/flight-auth-phoenix \
  flight_auth verify <auth_key> --expire 3600

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
