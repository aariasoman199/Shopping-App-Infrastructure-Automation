packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "image" {
  ami_name      = local.ami_name
  source_ami    = var.base_ami_id
  instance_type = "t2.micro"
  ssh_username  = "ec2-user"

  tags = {
    Name    = local.ami_name
    Project = var.project_name
    Environment = var.environment
  }
}

build {
  sources = [ "source.amazon-ebs.image" ]

  provisioner "shell" {
    script           = "./setup.sh"
    execute_command  = "sudo {{.Path}}"
  }

  provisioner "file" {
    source      = "../website"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo cp -r /tmp/website/* /var/www/html",
      "sudo chown -R apache:apache /var/www/html/",
      "sudo rm -rf /tmp/website"
    ]
  }
}
