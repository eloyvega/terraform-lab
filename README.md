# Laboratorio de Terraform

Taller de introducción a [Terraform](https://terraform.io)

## Introducción

Este laboratorio utiliza Terraform para crear la infraestructura necesaria para crear una base de datos y una aplicación web servida por un grupo auto escalable y sus recursos de red (VPC, Subnets, IGW, Route tables, Load Balancer, etc).

## Preparación del ambiente

Desplegar IDE de Cloud9 con este repositorio en la región us-east-1 (N. Virginia):

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=terraform-lab-env&templateURL=https://cloudtitlan-public-cfn-templates.s3.amazonaws.com/terraform-lab.json)

Cuando el stack de CloudFormation termine de ejecutarse, dirígete a Cloud9 en tu consola de AWS y busca el environment llamado `Terraform Lab` y click en `Open IDE`.

En tu terminal, dirígete hacia el directorio del repositorio. Todos las instrucciones se realizaran con relación a esta ubicación:

```
cd terraform-lab
```

Ejecuta el siguiente comando para instalar Terraform en este ambiente de Cloud9 y recargar la terminal:

```
./setup.sh
source ~/.bashrc
```

## Taller

### 01. Recursos base

- Crea un archivo `main.tf` y agrega el siguiente contenido

```terraform
terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region = var.aws_region
}
```

- Crea el archivo `vars.tf` donde pondremos todas las variables necesarias para este taller, empieza con la región de AWS que ocuparemos:

```
variable "aws_region" {
  default = "us-east-1"
}
```

Inicializa Terraform con el siguiente comando:

```
terraform init
```

### 02. Recursos de red

- Iniciamos con las variables y sus valores para nuestra red, agrega al archivo `vars.tf` lo siguiente:

```terraform
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
  default = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  default = "10.0.2.0/24"
}

variable "private_subnet_cidr_1" {
  default = "10.0.3.0/24"
}

variable "private_subnet_cidr_2" {
  default = "10.0.4.0/24"
}
```

- Crea el archivo `vpc.tf` para crear los recursos de red necesarios:

1. Una VPC
2. Dos subnets privadas
3. Dos subnets públicas
4. Un Internet Gateway
5. Una tabla de ruteo con tráfico público y sus asociaciones
6. Una tabla de ruteo privada y sus asociaciones

- Para crear la VPC:

```terraform
resource "aws_vpc" "lab_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "TerraformLabVPC"
  }
}
```

- Crea una subnet publica y una subnet privada:

```terraform
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet 1"
  }
}
```

- **RETO:** Crea la subnet pública y la subnet privada faltantes. Puedes utilizar `us-east-1b` para las zonas de disponibilidad de las redes faltantes

- Crea el internet gateway:

```terraform
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "VPC IGW"
  }
}
```
- Y la tabla de ruteo pública y la asociación de la subnet pública:

```terraform
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Subnet RT"
  }
}

resource "aws_route_table_association" "public-rt-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-rt-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-rt.id
}
```

- **RETO:** Crea la tabla de ruteo privada y las dos asociaciones de subnets privadas

- Ejecuta el siguiente comando para verificar que tus archivos de configuración sean correctos y ver el plan de ejecución:

```
terraform plan
```

- Aplica los cambios para crear la VPC y sus recursos:

```
terraform apply
```

Contesta `yes` cuando te pida confirmación

### 03. Web Server

- En el archivo `vars.tf` agrega las siguientes variables y sus valores:

```terraform
variable "ami_id" {
  default = ""
}

variable "server_port" {
  default = "8080"
}
```

- **RETO:** Para obtener el valor de la variable `ami_id`, dirígete a la consola de EC2 y busca el AMI ID de `Ubuntu Server 18.04 LTS (HVM), SSD Volume Type (64-bit x86)` 

- Crea el archivo `web_server.tf` donde alojaremos los siguientes recursos:

1. Security Groups
2. Load Balancer
3. Launch Configuration
4. Auto Scaling Group

- El siguiente bloque crea el Security Group que será vinculado con las instancias EC2, donde se alojará el sitio web desde el puerto especificado en la variable `server_port`

```terraform
resource "aws_security_group" "instance" {
  name   = "web-instance-sg"
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

- El Security Group para el Load Balancer es:

```terraform
resource "aws_security_group" "elb" {
  name   = "web-elb-sg"
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

- **RETO:** Investiga en la documentación de Terraform de [Security Groups](https://www.terraform.io/docs/providers/aws/r/security_group.html) para cerrar el tráfico del SG `web-instance-sg` únicamente al id del SG `web-elb-sg` en lugar del atributo `cidr_blocks`.

- A continuación creamos el Load Balancer para nuestra aplicación

```terraform
resource "aws_elb" "web_lb" {
  name               = "terraform-asg-example"
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
  security_groups    = [aws_security_group.elb.id]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}
```

- Finalmente creamos nuestro Launch Configuration y el Auto Scaling Group para esta aplicación:

```terraform
resource "aws_launch_configuration" "web_lc" {
  image_id        = var.ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_lc.id
  vpc_zone_identifier  = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]

  load_balancers    = [aws_elb.web_lb.name]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}
```

- **RETO:** Investiga el uso de [aws_autoscaling_schedule](https://www.terraform.io/docs/providers/aws/r/autoscaling_schedule.html) en Terraform y crea un horario para prender los servidores a las 9:00 horas y apagarlos a las 20:00 horas.

- Ejecuta el siguiente comando para verificar que tus archivos de configuración sean correctos y ver el plan de ejecución:

```
terraform plan
```

- Aplica los cambios para crear la VPC y sus recursos:

```
terraform apply
```

Contesta `yes` cuando te pida confirmación

- Espera unos minutos y visita la URL del Load Balancer que puedes encontrar en la consola de EC2. Tu navegador debería mostrar el mensaje `Hello, World`.

- **RETO:** Crea un archivo `outputs.tf` y crea el bloque `output` de Terraform necesario para ver el DNS del Load Balancer. Verifica que funcione haciendo un `terraform apply` nuevamente.

### 04. Base de Datos

- **RETO:** Crea los recursos necesarios en el arhivo `database.tf` para levantar una base de datos [MySQL en RDS](https://www.terraform.io/docs/providers/aws/r/db_instance.html), con su Security Group (puerto 3306 abierto hacia el SG instance) y [Subnet Group](https://www.terraform.io/docs/providers/aws/r/db_subnet_group.html) en las subnets privadas que creamos en el archivo `vpc.tf`

### 05. Conectando el web server a la base de datos

- Crea el archivo `user_data.sh` y agrega lo siguiente:

```sh
#!/bin/bash
apt-get update -y
apt-get install -y php apache2 libapache2-mod-php php-mysql
rm -f /var/www/html/index.html
cat > /var/www/html/index.php <<EOF
<?php
\$servername = "${database_address}";
\$username = "admin";
\$password = "P455w0rd";
\$conn = new mysqli(\$servername, \$username, \$password);
if (\$conn->connect_error) {
die("Connection failed: " . \$conn->connect_error);
} 
echo "Connected successfully";
?>
EOF
systemctl restart apache2
```

- Modifica el archivo `web_server.tf` para agregar el siguiente bloque que lee el archivo e inserta el valor de la dirección de la base de datos

```terraform
data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    database_address = aws_db_instance.database.address
  }
}
```

- Modifica el recurso `aws_launch_configuration` con el nuevo `user_data`

```terraform
resource "aws_launch_configuration" "web_lc" {
  image_id        = var.ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}
```

- Planea y ejecuta los script de Terraform con:

```
terraform plan
terraform apply
```

- Visita la URL del Load Balancer y verifica que la conexión a la base de datos es exitosa.
