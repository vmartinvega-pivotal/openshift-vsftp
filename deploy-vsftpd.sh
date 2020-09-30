#!/usr/bin/env bash

set -eu

function Help()
{
   # Display Help
   echo
   echo
   echo "Add description of the script options."
   echo
   echo "Syntax: deploy-vsftpd.sh "
   echo "options:"
   echo 
   echo "-t|--token          Token used to authenticate to openshift."
   echo "-p|--endpoint       Openshift endpoint. Required"
   echo "-u|--user           Vsftpd user to create. Default value: admin."
   echo "-a|--serviceaccount Service account to run the pod. MUST exits."
   echo "-n|--namespace      Project name where vsftpd will be deployed. This parameter is required."
   echo "-e|--environment    Environment on which the rabbitmq will be deployed, tipically this parameter will have one of the following values: cert, pre or pro. Default value cert."
   echo "-c|--server         Server name. Default value vsftpdserver."
   echo "-s|--storageclass   Storage class to be used in the storage claim. Default value shared-gold."
   echo "-i|--image          Docker image to deploy. Default value registry.global.ccc.srvb.can.paas.cloudcenter.corp/c3alm-sgt/rabbitmq."
   echo "-v|--volumesize     Volume size. Default value 1Gi."
   echo "-h|--help           This message."
   echo
}

endpoint=""
namespace=""
vsftpduser=""
environment=""
storageclass=""
servername=""
vsftpdimage=""
volumesize=""
environment=""
token=""
serviceaccount=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-t|--token)
			token="$2"
			shift 2
	
  		;;
		-n|--namespace)
			namespace="$2"
			shift 2
			;;
		-e|--environment)
			environment="$2"
			shift 2
			;;
		-u|--user)
			vsftpduser="$2"
			shift 2
			;;
		-a|--serviceaccount)
			serviceaccount="$2"
			shift 2
			;;
		-s|--storageclass)
			storageclass="$2"
			shift 2
			;;
		-p|--endpoint)
			endpoint="$2"
			shift 2
			;;
		-c|--server)
			servername="$2"
			shift 2
			;;
		-i|--image)
			vsftpdimage="$2"
			shift 2
			;;
		-v|--volumesize)
			volumesize="$2"
			shift 2
			;;
    -h|--help)
			Help
			exit 0
			;;
		-*)
			echo "ERROR: Unknown option '$1'"
      Help
			exit 1
			;;
		*)
			break
			;;
	esac
done

namespace="myproject"
endpoint="https://172.18.44.135:8443"
serviceaccount="vsftpd"

echo ""
if [[ "${endpoint:-}" == "" ]]; then
  echo "The endpoint is required! Existing..."
  exit 1
fi

if [[ "${serviceaccount:-}" == "" ]]; then
  echo "The serviceaccount is required! Existing..."
  exit 1
fi

if [[ "${namespace:-}" == "" ]]; then
  echo "The project/namespace is required! Existing..."
  exit 1
else
  echo "A new vsftpd server will be created with the following values"
  echo ""
  echo "Using endpoint (${endpoint})"
  echo "Using project (${namespace})"
  echo "Using serviceaccount (${serviceaccount})"
fi

if [[ "${servername:-}" == "" ]]; then
  servername="vsftpdserver"
  echo "Using default server name (${servername})"
else
  echo "Using server name (${clustername})"
fi

if [[ "${vsftpduser:-}" == "" ]]; then
  vsftpduser="admin"
  echo "Using default vsftpd user (${vsftpduser})"
else
  echo "Using vsftpd user (${vsftpduser})"
fi

echo "Random password for the user (${vsftpduser})"

if [[ "${vsftpdimage:-}" == "" ]]; then
  vsftpdimage="registry.global.ccc.srvb.can.paas.cloudcenter.corp/c3alm-sgt/vsftpd"
  echo "Using default vsftpd image (${vsftpdimage})"
else
  echo "Using vsftpd image (${vsftpdimage})"
fi

if [[ "${environment:-}" == "" ]]; then
  environment="cert"
  echo "Using default environment (${environment})"
else
  echo "Using environment (${environment})"
fi

if [[ "${storageclass:-}" == "" ]]; then
  storageclass="shared-gold"
  echo "Using default storage class (${storageclass})"
else
  echo "Using storage class (${storageclass})"
fi

if [[ "${volumesize:-}" == "" ]]; then
  volumesize="1Gi"
  echo "Using default volume size (${volumesize})"
else
  echo "Using volume size (${volumesize})"
fi

volumeclaimname=${servername}"-storage-"${environment}
echo "Using volume claim (${volumeclaimname})"
echo

if [[ -n "${token}" ]]; then
  echo "Trying to login ${endpoint} with token..."
  if ! oc login "${endpoint}" --token="${token}" > /dev/null 2>&1; then
    echo "ERROR: Could not login to ${endpoint} with the specified token"
    exit 1
  else 
    echo "Login successful."
  fi
else
  echo "Trying to login ${endpoint} with username and password..."
  echo
  #read -r -p "Username: " username
  #read -r -s -p "Password: " password
  username=""
  password=""
  echo

  #if ! oc login "${endpoint}" -u "${username}" --password="${password}" --insecure-skip-tls-verify=true > /dev/null 2>&1; then
  #  echo "ERROR: Could not login to ${endpoint} with user ${username}"
  #  exit 1
  #else  
  #  echo "Login successful."
  #fi
  oc login -u system:admin
fi

echo
#read -p "Do you want to proceed (y/n)? " -n 1 -r
REPLY="y"
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Creating vsftpd server..."
    echo
    oc process \
    -f "vsftpd-template.yaml" \
    -o yaml \
    -p NAMESPACE="${namespace}" \
    -p FTP_USER="${vsftpduser}" \
    -p FTP_PASS="admin" \
    -p SERVER_NAME="${servername}" \
    -p VOLUME_CLAIM_NAME="${volumeclaimname}" \
    -p VOLUME_SIZE="${volumesize}" \
    -p STORAGE_CLASS_NAME="${storageclass}" \
    -p SERVICE_ACCOUNT="${serviceaccount}" \
    -p ISTAG="${vsftpdimage}" \
  | \
  oc create -f -

  echo 
  echo "Run the following commands in order to remove all created objects..."
  echo
  echo "oc delete secret ${servername}-secret"
  echo "oc delete configmap ${servername}-config"
  echo "oc delete service ${servername}-balancer"
  echo "oc delete statefulset ${servername}"
  echo "oc delete pvc ${volumeclaimname}-${servername}-0"
fi