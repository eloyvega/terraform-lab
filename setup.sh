#!/usr/bin/env bash

# Install terraform
mkdir -p .bin
cd .bin
wget https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_amd64.zip
unzip terraform_0.12.7_linux_amd64.zip
rm -f terraform_0.12.7_linux_amd64.zip
echo PATH=$PATH:$(pwd) >> ~/.bashrc
source ~/.bashrc

echo Successfully installed $(terraform version)