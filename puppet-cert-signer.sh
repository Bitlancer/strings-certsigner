#!/bin/bash

# Global vars

## Testing mode
TESTING=1

## Verbosity
VERBOSE=1

## Contains ldap variables
source ldap-vars.inc

# Functions

function main {
  # Main
  
  # For capturing cmd output
  local output=""

  # Get the cert list from puppet 
  if [ $VERBOSE -eq 1 ]; then
    echo "Getting puppet cert list"
  fi
  local certs=$(get_cert_list)
  if [ $? -ne 0 ]; then
    echo "Failed to get puppet cert list"
    echo "$certs"
    exit 1
  fi
  
  # Parse the cert list into an array
  local OFS=$IFS
  IFS=$'\n'
  read -ra certs <<< "$certs"
  IFS=$OFS
  
  for cert in "${certs[@]}"; do

    # Parse cert line
    read -ra cert_details <<< "$cert"
    local host="${cert_details[0]}"

    if [ $VERBOSE -eq 1 ]; then
      echo "Processing cert for $host"
    fi
    
    # Search ldap for the host
    find_host "$host"
    local result=$?
    if [ $result -eq 0 ]; then
      sign_host_cert "$host"
    elif [ $result -eq 1 ]; then
      clear_host_cert "$host"
    fi
  done
}

function get_cert_list {
  # Get the list of unsigned certs from puppet

  if [ $TESTING -eq 1 ]; then
    echo "uneffectible.dfw01.bitlancer-infra.net (FD:E7:41:C9:2C:B7:5C:27:11:0C:8F:9C:1D:F6:F9:46)"
    return 0
  else
    sudo puppet cert list
    return $?
  fi
}

function resolve_host_address {
  # Resolve a host's address
  
  local host="$1"

  dig +short "$host"
  return $?
}

function find_host {
  # Search ldap for a host by fqdn and ip address
  
  local host="$1"
  
  local output=""
  local search_filter="(&(objectClass=puppetClient)(cn=$host))"

  if [ $VERBOSE -eq 1 ]; then
    echo "Searching LDAP for $host using filter $search_filter"
  fi
  
  output=$(ldapsearch -ZZ -h $ldaphost -D $ldapbinddn -w $ldappass -b $ldapbasedn $search_filter 2>&1)
  if [ $? -ne 0 ]; then
    echo "LDAP search failed:"
    echo "$output"
    return 2
  elif [ $VERBOSE -eq 1 ]; then
    echo "$output"
  fi

  echo $output | grep "$host" > /dev/null
  return $?
}

function sign_host_cert {
  # Sign a host's certificate
  
  local host="$1"
  
  local output=""

  if [ $VERBOSE -eq 1 ]; then
    echo "Signing $host's certificate"
  fi

  if [ $TESTING -eq 1 ]; then
    return 0
  fi
  
  output=$(sudo puppet cert sign "$host" 2>&1)
  if [ $? -ne 0 ]; then
    echo "Failed to sign cert for $host"
    echo $output
    return 1
  else
    return 0
  fi
}

function clear_host_cert {
  # Clean (remove) a host's certificate
  
  local host="$1"
  
  local output=""

  if [ $VERBOSE -eq 1 ]; then
    echo "Clearing $host's certificate"
  fi

  if [ $TESTING -eq 1 ]; then
    return 0
  fi
  
  output=$(sudo puppet cert --clean "$host" 2>&1)
  if [ $? -ne 0 ]; then
    echo "Failed to clear cert for $host"
    echo $output
    return 1
  else
    return 0
  fi
}

# Run
main $@
