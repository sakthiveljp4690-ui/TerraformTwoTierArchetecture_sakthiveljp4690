data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_iam_role" "ec2_ssm_role" {
    name = "ec2_ssm_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
    role = aws_iam_role.ec2_ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.ec2_ssm_role.name 
}
resource "aws_security_group" "security_groups" {

    ingress {
        description = "webserver"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "allow tcp sg"
    }
}

resource "aws_eip" "free_tier_eip" {
    instance = aws_instance.free_tier_ec2.id
    domain = "vpc"
}

resource "aws_instance" "free_tier_ec2" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    vpc_security_group_ids = [ aws_security_group.security_groups.id ]
    root_block_device {
    volume_size = 8
    volume_type = "gp3"
    }
    tags = {
        Name = "terraform-free-tier"
    }
}

