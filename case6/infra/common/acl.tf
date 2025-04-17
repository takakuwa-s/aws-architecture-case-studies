# プライベートサブネット用のNetwork ACL
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl.html
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_subnets[*].id

  # インバウンドルール - (80)トラフィックを許可
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/14" # 10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16を許可
    from_port  = 80
    to_port    = 80
  }

  # アウトバウンドルール - HTTP (80)トラフィックを許可
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # インバウンドルール - HTTPS (443)トラフィックを許可
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 443
    to_port    = 443
  }

  # アウトバウンドルール - HTTPS (443)トラフィックを許可
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # インバウンドルール - 一時ポート（エフェメラルポート）を許可
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # アウトバウンドルール - 一時ポート（エフェメラルポート）を許可
  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
}
