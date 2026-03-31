# Security group para o RDS
resource "aws_security_group" "rds" {
  name   = "bia-rds-sg"
  vpc_id = aws_vpc.bia.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bia-rds-sg" }
}

resource "aws_db_subnet_group" "bia" {
  name       = "bia-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = { Name = "bia-db-subnet-group" }
}

resource "aws_db_instance" "bia" {
  identifier        = "db-bia-eks"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.bia.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  publicly_accessible     = false
  deletion_protection     = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "bia-rds-final-snapshot"

  tags = { Name = "db-bia-eks" }
}
