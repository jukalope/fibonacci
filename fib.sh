#!/bin/bash
# Fibonacci getter: echos the nth fibonacci number in the sequence, with various methods.

function usage()
{
  echo -e "
Usage: $0 INDEX [MODE]

  INDEX:      positive integer representing the desired value of Fibonacci sequence, 1-based
  MODE:
    -m        Use classic memory-caching method (default)
    -c        Use closed-form expression method
    -t        Do a time trial, comparing 1000 iterations of -m and -c

EXAMPLES:
  $0 50 -m
  $0 50 -c
  $0 50 -t
"
  [ -z "$1" ] && return     # No error, just return
  echo -e "$2 \n"
  exit $1
}

[ -z "$1" ]              && usage 0
[[ "$1" =~ ^-*[0-9]+$ ]] || usage 2 "ERROR: desired Fibonacci sequence index must be an integer value"
[ "$1" -ge 1 ]           || usage 3 "ERROR: desired Fibonacci sequence index must be a positive integer value"
[ "$1" -gt 92 -o "$1" -lt 1 ] && usage 4 "ERROR: Fibonacci sequence index must be in range 1 .. 92"

function fib_closed    # Equation from: https://fabiandablander.com/r/Fibonacci.html
{
  n=$1
  result_float=$(echo "1 / $RT5 * (((1 + $RT5) / 2)^$n - ((1 - $RT5) / 2) ^ $n)" | bc -S 20)  # pipe to bc with scale precision to keep the evaluation accurate
  CLOSED_RESULT=$(printf "%.0f\n" $(bc <<< "$result_float"))
}

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

function time_trial
{
  OUTFILE=/dev/null  # set to /dev/null to avoid messy output; we only care about the calc time
  echo -n "___classic"
  time for t in {1..100}; do r=$((RANDOM%92+1)); fib_classic $r; done
  echo
  echo -n "___closed"
  time for t in {1..100}; do r=$((RANDOM%92+1)); fib_closed $r; done
}

function env_check
{
  echo 1.23 | bc -S 20 >/dev/null 2>&1 || { echo "ERROR: Must run on system with 'bc' utility >= version 6.5.0"; exit 1; }
}

#________________________________________________________________________________________________________________

env_check

CLOSED_RESULT=0
FIB=(1 1)                         # Our FIB array, pre-seeded with 2 values for generating the rest  (for fib_classic)
RT5=$(echo "sqrt(5)" | bc -S 20)  # Square root of 5, calculated once here to save time; used        (for fib_closed)

[ -z "$2"      ] && fib_classic $1 && echo ${FIB[$(($1-1))]} && exit 0
[ "$2" == "-m" ] && fib_classic $1 && echo ${FIB[$(($1-1))]} && exit 0
[ "$2" == "-c" ] && fib_closed  $1 && echo $CLOSED_RESULT    && exit 0
[ "$2" == "-t" ] && time_trial || usage 4 "ERROR: only available options are -c, -m, -t"

