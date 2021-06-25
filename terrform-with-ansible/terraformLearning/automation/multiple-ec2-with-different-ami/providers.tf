provider "aws" {
    region     = "us-east-2"
    profile = "sagar"
}

resource "aws_key_pair" "ec2-testing-terraform" {
  key_name   = "ec2-testing-terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAudaHbo71fMcr+QdJxj9ymmnfmAlbXC4ZnbOrrRHaAEAznIEDuxvdqxqsgrQEHRN2T2wZIHgXHjyEL65ebrGHxAJuavxaYPBLOnckVxA/6LEkkcY51+a7KX+9dL/Vb3TMdylSahGAbtyTxnZIbkp1TC5QsBvQsyHevxE3grrw5cBimgPWiGachYFdt0L5rFWUFqxIHtEgy0hSKUYE1sFYdHHfbv+zitgNn+F0q7f9CtX11eO7zVSvZluTyoMzT41erQVUZ4VpoWcD90WfVdKAnCDx0zM3No3SIYzBj2sR3Z+ELKGuYOn/hqrY6ugmlwAo1yAeADD5s/k9WaAiJHl1kS51ecU5VUX7rl5Vyro0j1b6lDntOJ/Bv1/EFxsThmnbHtt/c7Co3hacLPUWlQG3SOTbwiNWgFhfLATYinImlL8qSdwPEwsvaExqtgLpTwST/XH7iqqNe/e3VbJplRQb7sLn/yW/j8IoHyZpxs/Yvl3pxXaGHDXoBaOb9+zOe08= sagar@sagar-pc"
}

variable "vpc_id" {
    default = "vpc-81ff60ea"
}

resource "aws_security_group" "aws_security_group_ts" {
  name        = "aws_security_group_ts"
  description = "custom security group "
  vpc_id      = "${var.vpc_id}"

  ingress {
    description      = "post 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "post 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


variable "amazon_ami_id" {
    default = "ami-0d8d212151031f51c"
}

variable "ubuntu_ami_id" {
    default = "ami-00399ec92321828f5"
}

variable "user_name" {
    default = "ubuntu"
}
variable "MY_USER_PUBLIC_KEY" {
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAudaHbo71fMcr+QdJxj9ymmnfmAlbXC4ZnbOrrRHaAEAznIEDuxvdqxqsgrQEHRN2T2wZIHgXHjyEL65ebrGHxAJuavxaYPBLOnckVxA/6LEkkcY51+a7KX+9dL/Vb3TMdylSahGAbtyTxnZIbkp1TC5QsBvQsyHevxE3grrw5cBimgPWiGachYFdt0L5rFWUFqxIHtEgy0hSKUYE1sFYdHHfbv+zitgNn+F0q7f9CtX11eO7zVSvZluTyoMzT41erQVUZ4VpoWcD90WfVdKAnCDx0zM3No3SIYzBj2sR3Z+ELKGuYOn/hqrY6ugmlwAo1yAeADD5s/k9WaAiJHl1kS51ecU5VUX7rl5Vyro0j1b6lDntOJ/Bv1/EFxsThmnbHtt/c7Co3hacLPUWlQG3SOTbwiNWgFhfLATYinImlL8qSdwPEwsvaExqtgLpTwST/XH7iqqNe/e3VbJplRQb7sLn/yW/j8IoHyZpxs/Yvl3pxXaGHDXoBaOb9+zOe08= sagar@sagar-pc"
}
resource "aws_instance" "my_instance2" {
  ami           = "${var.ubuntu_ami_id}"
  instance_type = "t2.micro"
  key_name = "ec2-testing-terraform"
  vpc_security_group_ids = ["${aws_security_group.aws_security_group_ts.id}"]

    provisioner "remote-exec" {
        inline = [
            "sudo adduser --disabled-password --gecos '' ec2-user",
            "sudo mkdir -p /home/ec2-user/.ssh",
            "sudo touch /home/ec2-user/.ssh/authorized_keys",
            "sudo echo '${var.MY_USER_PUBLIC_KEY}' > authorized_keys",
            "sudo mv authorized_keys /home/ec2-user/.ssh",
            "sudo chown -R ec2-user:ec2-user /home/ec2-user/.ssh",
            "sudo chmod 700 /home/ec2-user/.ssh",
            "sudo chmod 600 /home/ec2-user/.ssh/authorized_keys",
            "sudo usermod -aG sudo ec2-user",
            "echo 'ec2-user  ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ec2-user"
        ]
        connection {
            user     = "ubuntu"
            host = aws_instance.my_instance2.public_ip
        }

    }
    tags = {
        Name = "node1"
    }
}
resource "aws_instance" "my_instance3" {
  ami           = "${var.amazon_ami_id}"
  instance_type = "t2.micro"
  key_name = "ec2-testing-terraform"
  vpc_security_group_ids = ["${aws_security_group.aws_security_group_ts.id}"]
  tags = {
    Name = "node2"
  }
}
resource "aws_instance" "my_instance1" {
  ami           = "${var.amazon_ami_id}"
  instance_type = "t2.micro"
  key_name = "ec2-testing-terraform"
  vpc_security_group_ids = ["${aws_security_group.aws_security_group_ts.id}"]
  tags = {
    Name = "ansible server"
  }
}


resource "null_resource" "copy_execute" {
    connection {
        type = "ssh"
        host = aws_instance.my_instance1.public_ip
        user = "ec2-user"
        private_key = file("/home/sagar/.ssh/ec2-testing-terraform.pem")
    }


    provisioner "local-exec" {
        command = "echo ${aws_instance.my_instance1.public_dns} > inventory"
    }

    provisioner "local-exec" {
        command = "echo ${aws_instance.my_instance2.public_dns} >> inventory"
    }
    provisioner "local-exec" {
        command = "echo ${aws_instance.my_instance3.public_dns} >> inventory"
    }
    provisioner "local-exec" {
        command = "ansible-playbook main.yml "
    }

    depends_on = [ aws_instance.my_instance1,aws_instance.my_instance2,aws_instance.my_instance3 ]
  
}









output "ip" {
  value = aws_instance.my_instance1.public_ip
}

output "publicName1" {
  value = aws_instance.my_instance1.public_dns
}

output "publicName2" {
  value = aws_instance.my_instance2.public_dns
}

output "publicName3" {
  value = aws_instance.my_instance3.public_dns
}

