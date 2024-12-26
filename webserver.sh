#!/bin/bash
# Webserver to serve fibonacci numbers by index
#
# Start this script in a terminal session, then to get the 20th fibonacci number:
#   Visit http://127.0.0.1:3000/get?n=20
#     OR
#   curl http://127.0.0.1:3000/get?n=20

#_____ Fibonacci ___________________________________________________________________________________________________________

FIB=(1 1)                                      # Our FIB array, pre-seeded with 2 values for generating the rest

function fib_classic
{
  n=$(($1 - 1))                                # Convert n to 0-based index of FIB
  [ ${#FIB[@]} -gt $n ] && return              # If we have at least this many indices, just return

  for i in $(seq ${#FIB[@]} $n); do            # Calculate more fib numbers up to the desired one (n)
    max_index=$(( $i - 1 ))
    prv_index=$(( $i - 2 ))
    max_value=${FIB[$max_index]}
    prv_value=${FIB[$prv_index]}
    next_item=$(( $prv_value + $max_value ))   # Calculate next fib value
    FIB+=( $next_item )                        # Append to our FIB array
  done
}

#_____ Webserver ___________________________________________________________________________________________________________

CFG_FILE=ws.cfg
FIB_PORT=$(cat $CFG_FILE | grep ^port | cut -d'=' -f2)
rm -f RESPONSE_FIFO
mkfifo RESPONSE_FIFO            # Use a FIFO with netcat below to behave as a server
shopt -s lastpipe 2>/dev/null   # bash > 4.2 supports lastpipe shell option to preserve our env (global FIB var) when passed through pipes


function handle_request
{
  local request=""
  local response=""

  while read line; do
            # Parse the 1st (HTTP) line to get the "GET" + "/get?n=___" info
              # GET /get?n=5 HTTP/1.1
              # Host: 127.0.0.1:3000
              # User-Agent: curl/8.7.1
              # Accept: */*

    line=$(echo $line | tr -d '[\r\n]')                                # remove all linebreaks
    [ -z "$line" ] && break                                            # skip empty lines
    HEADLINE_REGEX='(.*)[[:blank:]](.*)[[:blank:]]HTTP.*'

    if [[ $line =~ $HEADLINE_REGEX ]]; then
      request=$(echo $line | sed -E "s/$HEADLINE_REGEX/\1 \2/")
    fi
  done

  if [[ "$request" =~ GET[[:blank:]]+/get\?n=([[:digit:]]+) ]]; then   # /get?n=5
    n=$(echo $request | awk '{print $NF}' | cut -d'=' -f2)             # n is requested fibonacci index
    if [ "$n" -gt 92 -o "$n" -lt 1 ]; then
      response="HTTP/1.1 416 Out of range\r\n\r\n\r\nFibonacci index \"$n\" not supported. Try between 1 .. 92"
    else
      fib_classic $n               # call it to ensure our global array will have the desired index
      # echo ==$$____${FIB[$n]}___${#FIB[@]}___${FIB[*]}
      response="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n${FIB[$n]}"
    fi
  else
    response="HTTP/1.1 404 NotFound\r\n\r\n\r\nNot Found"
  fi

  echo -e $response > RESPONSE_FIFO
}

function env_check
{
  [ -f $CFG_FILE ] && grep -q -e "^port=" $CFG_FILE || { echo "ERROR: Missing config file '$CFG_FILE' with entry 'port=....'"; exit 1; }
}


env_check

echo "Listening on ${FIB_PORT}..."
while true; do
  cat RESPONSE_FIFO | nc -l $FIB_PORT | handle_request
done
