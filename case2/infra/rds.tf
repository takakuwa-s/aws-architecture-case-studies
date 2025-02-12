# RDS 用のサブネットの集合
# RDS インスタンスは、DB サブネットグループ内のどれかのサブネットに配置される
# Multi-AZ の場合、プライマリ DB とセカンダリ DB は異なる AZ のサブネットに配置される
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "rds" {
  identifier             = "mydb"
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  multi_az               = true
  username               = "admin"
  password               = "mypassword"
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}
