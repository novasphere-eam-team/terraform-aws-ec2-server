resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "SSH restreint au CIDR admin, ports applicatifs choisis"

  ingress {
    description = "SSH restreint"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  dynamic "ingress" {
    for_each = toset(var.open_ports)
    content {
      description = "Port applicatif ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Sortie autorisee"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nouveau SG cree avant la destruction de l'ancien : pas de coupure lors d'un remplacement
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = merge(var.tags, {
    Name = var.name
    Role = var.role
  })
}
