# Laboratorio de Terraform

Taller de introducción a [Terraform](https://terraform.io)

## Preparación del ambiente

Desplegar IDE de Cloud9 con este repositorio en la región us-east-1 (N. Virginia):

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=terraform-lab-env&templateURL=https://cloudtitlan-public-cfn-templates.s3.amazonaws.com/terraform-lab.json)

Cuando el stack de CloudFormation termine de ejecutarse, dirígete a Cloud9 en tu consola de AWS y busca el environment llamado `Terraform Lab` y click en `Open IDE`

En tu terminal, dirígete hacia el directorio del repositorio. Todos las instrucciones se realizaran con relación a esta ubicación:

```
cd wildrydes-serverless
```

Serverless es una herramienta de consola (CLI) desarrollada con NodeJS y se instala con npm de la siguiente forma:

```
npm install -g serverless
```