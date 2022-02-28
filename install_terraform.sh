#!/usr/bin/env bash
ostype=""
tf_version="1.1.2"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux
        ostype="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        ostype="darwin"
else
    echo "Unsupported platform $OSTYPE"
    exit 1
fi

if [ ! -f ./terraform ]; then
    url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_${ostype}_amd64.zip"
    curl -sS $url > terraform.zip
    unzip -o terraform.zip
    rm terraform.zip
    ./terraform init
fi
