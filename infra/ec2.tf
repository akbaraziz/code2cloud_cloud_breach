#IAM Role
resource "aws_iam_role" "code2cloud-ec2-role" {
  name               = "code2cloud-ec2-role-${var.code2cloudid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name      = "code2cloud-ec2-role-${var.code2cloudid}"
    Stack     = "${var.stack-name}"
    Scenario  = "${var.scenario-name}"
    yor_trace = "2069e415-4b3f-47e1-b853-acf1fce1b459"
  }
}

#Iam Role Policy
resource "aws_iam_policy" "code2cloud-ec2-role-policy" {
  name        = "code2cloud-ec2-role-policy-${var.code2cloudid}"
  description = "code2cloud-ec2-role-policy-${var.code2cloudid}"
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "s3:*",
              "cloudwatch:*",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "iam:PassRole",
              "iam:ListAttachedUserPolicies",
              "iam:GetRole",
              "iam:GetRolePolicy",
              "ec2:DescribeInstances",
              "ec2:CreateKeyPair",
              "ec2:RunInstances",
              "ec2:TerminateInstances",
              "iam:ListRoles",
              "iam:ListInstanceProfiles",
              "iam:ListAttachedRolePolicies",
              "iam:GetPolicyVersion",
              "iam:GetPolicy",
              "ec2:AssociateIamInstanceProfile"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
  tags = {
    yor_trace = "d5811c8c-e1a2-47f7-9498-3f4efac2453f"
  }
}

#IAM Role Policy Attachment
resource "aws_iam_policy_attachment" "code2cloud-ec2-role-policy-attachment" {
  name = "code2cloud-ec2-role-policy-attachment-${var.code2cloudid}"
  roles = [
    "${aws_iam_role.code2cloud-ec2-role.name}"
  ]
  policy_arn = "${aws_iam_policy.code2cloud-ec2-role-policy.arn}"
}

#IAM Instance Profile
resource "aws_iam_instance_profile" "code2cloud-ec2-instance-profile" {
  name = "code2cloud-ec2-instance-profile-${var.code2cloudid}"
  role = "${aws_iam_role.code2cloud-ec2-role.name}"
  tags = {
    yor_trace = "9383d63a-de32-47bf-b9f6-cb60451e6a11"
  }
}

#Security Groups
resource "aws_security_group" "code2cloud-ec2-ssh-security-group" {
  name        = "code2cloud-ec2-ssh-${var.code2cloudid}"
  description = "code2cloud ${var.code2cloudid} Security Group for EC2 Instance over SSH"
  vpc_id      = "${aws_vpc.code2cloud-vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.code2cloud_whitelist]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.code2cloud-vpc.cidr_block]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name      = "code2cloud-ec2-ssh-${var.code2cloudid}"
    Stack     = "${var.stack-name}"
    Scenario  = "${var.scenario-name}"
    yor_trace = "6b197726-ef42-443b-8906-1d59d4b8ce71"
  }
}

resource "aws_security_group" "code2cloud-ec2-http-security-group" {
  name        = "code2cloud-ec2-http-${var.code2cloudid}"
  description = "code2cloud ${var.code2cloudid} Security Group for EC2 Instance over HTTP"
  vpc_id      = "${aws_vpc.code2cloud-vpc.id}"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.code2cloud_whitelist]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.code2cloud-ec2-ssh-security-group.id}",
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name      = "code2cloud-ec2-http-${var.code2cloudid}"
    Stack     = "${var.stack-name}"
    Scenario  = "${var.scenario-name}"
    yor_trace = "ce99a537-2e7c-4a1e-aead-0e04a6733194"
  }
}

#AWS Key Pair
resource "aws_key_pair" "code2cloud-ec2-key-pair" {
  key_name   = "code2cloud-ec2-key-pair-${var.code2cloudid}"
  public_key = "${file(var.ssh-public-key-for-ec2)}"
  tags = {
    yor_trace = "b132f8f1-1641-44f9-bfe2-5ccd35543f20"
  }
}

#EC2 Instance
resource "aws_instance" "code2cloud-ubuntu-ec2" {
  ami                         = "ami-0a313d6098716f372"
  instance_type               = "t2.micro"
  iam_instance_profile        = "${aws_iam_instance_profile.code2cloud-ec2-instance-profile.name}"
  subnet_id                   = "${aws_subnet.code2cloud-public-subnet-1.id}"
  associate_public_ip_address = true
  private_ip                  = "10.10.10.103"
  vpc_security_group_ids = [
    "${aws_security_group.code2cloud-ec2-ssh-security-group.id}",
    "${aws_security_group.code2cloud-ec2-http-security-group.id}"
  ]
  key_name = "${aws_key_pair.code2cloud-ec2-key-pair.key_name}"
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }
  provisioner "file" {
    source      = "../app/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh-private-key-for-ec2)}"
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "scripts/script.sh"
    destination = "/home/ubuntu/script.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh-private-key-for-ec2)}"
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "scripts/initial_setup.sh"
    destination = "/home/ubuntu/initial_setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh-private-key-for-ec2)}"
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/initial_setup.sh",
      "/home/ubuntu/initial_setup.sh",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh-private-key-for-ec2)}"
      host        = self.public_ip
    }
  }
  tags = {
    Name      = "code2cloud-ubuntu-ec2-${var.code2cloudid}"
    Stack     = "${var.stack-name}"
    Scenario  = "${var.scenario-name}"
    yor_trace = "f1c79839-bd48-4fbd-9fd3-123365bd356e"
  }
}

output "code2cloud-ec2-public-ip" {
  value = aws_instance.code2cloud-ubuntu-ec2.public_ip
}

output "code2cloud-ec2-private-ip" {
  value = aws_instance.code2cloud-ubuntu-ec2.private_ip
}

output "code2cloud-ec2-key-pair" {
  value = aws_key_pair.code2cloud-ec2-key-pair.key_name
}
