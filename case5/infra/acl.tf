# プライベートサブネット用のNetwork ACL
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl.html
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.app-private[*].id

  # インバウンドルール - ALBからのHTTP (80)トラフィックを許可
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
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

  # インバウンドルール - VPCエンドポイントへのHTTPS (443)トラフィックを許可
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

  # インバウンドルール - Redis (6379)へのトラフィックを許可
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 6379
    to_port    = 6379
  }

  # アウトバウンドルール - Redis (6379)へのトラフィックを許可
  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 6379
    to_port    = 6379
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
