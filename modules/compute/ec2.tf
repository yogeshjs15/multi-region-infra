data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg-${var.region_name}"
  description = "Security group for EC2 in ${var.region_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow port ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ec2-sg-${var.region_name}"
    Environment = var.environment
    Region      = var.region_name
  }
}

resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd

              systemctl enable httpd
              systemctl start httpd

              echo "<h1>Welcome from ${var.region_name}</h1>" > /var/www/html/index.html
              echo "<h2>Environment: ${var.environment}</h2>" >> /var/www/html/index.html
              echo "<p>Region: ${var.region}</p>" >> /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.environment}-ec2-${var.region_name}-${count.index + 1}"
    Environment = var.environment
    Region      = var.region_name
  }
}
