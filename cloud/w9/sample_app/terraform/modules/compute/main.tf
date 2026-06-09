data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "k8s-key-week8"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.k8s_key.private_key_pem
  filename        = "${path.root}/k8s-key.pem"
  file_permission = "0400"
}

# Lưu Private Key lên AWS Systems Manager (SSM) Parameter Store để lấy lại sau khi deploy bằng CI/CD
resource "aws_ssm_parameter" "private_key" {
  name        = "/ec2/k8s-key-week9"
  description = "Private key for K8s Minikube Node"
  type        = "SecureString"
  value       = tls_private_key.k8s_key.private_key_pem
}

resource "aws_instance" "k8s_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = templatefile("${path.module}/init.sh", {
    app_port = var.app_port
  })

  tags = {
    Name = "K8s-Minikube-Node"
  }
}
