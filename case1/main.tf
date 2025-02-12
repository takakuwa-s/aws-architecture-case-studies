terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.1"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Environment = "dev"
      terraform   = "true"
      project     = "aws-architecture-case-study"
      case        = "case-study-1"
    }
  }
}

# VPCの作成（IPv4/IPv6 両方）
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # 自動的にIPv6を付与
  assign_generated_ipv6_cidr_block = true

  # VPC内でAmazonProvidedDNSを有効にする
  enable_dns_support = true

  # VPC内のパブリックIPアドレスが割り当てられたリソースに自動的にDNSホスト名を付与
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# インターネットゲートウェイの作成（IPv4/IPv6共通）
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Egress-Only Internet Gatewayの作成（IPv6用）
resource "aws_egress_only_internet_gateway" "eipgw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "egress-only-igw"
  }
}

# 利用可能なAZ一覧を取得
data "aws_availability_zones" "available" {
  state = "available"
}

# パブリックサブネットの作成（デュアルスタック）
resource "aws_subnet" "public" {
  count                           = length(data.aws_availability_zones.available.names)
  vpc_id                          = aws_vpc.main.id
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  cidr_block                      = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "public-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# プライベートサブネットの作成（デュアルスタック）
resource "aws_subnet" "private" {
  count                           = length(data.aws_availability_zones.available.names)
  vpc_id                          = aws_vpc.main.id
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  cidr_block                      = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 10)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "private-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# Elastic IP & NAT Gatewayの作成（IPv4用）
resource "aws_eip" "nat" {
  count                     = length(data.aws_availability_zones.available.names)
  associate_with_private_ip = null
}
resource "aws_nat_gateway" "nat" {
  count         = length(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# パブリック用ルートテーブルの作成（IPv4/IPv6共通）
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # IPv4 ルート
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # IPv6 ルート
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# パブリックサブネットへのルートテーブルの関連付け
resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# プライベート用ルートテーブルの作成（IPv4はNAT Gateway、IPv6はEgress-Only IGW）
resource "aws_route_table" "private" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.main.id

  # IPv4 ルート：プライベートサブネットからNAT Gateway経由でインターネットへ
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  # IPv6 ルート：プライベートサブネットからEgress-Only Internet Gateway経由でアウトバウンド通信
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.eipgw.id
  }

  tags = {
    Name = "private-rt-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# プライベートサブネットへのルートテーブルの関連付け
resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}