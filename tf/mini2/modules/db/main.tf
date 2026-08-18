resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "primary" {
  identifier_prefix      = "db-primary-"
  engine                 = "mysql"
  instance_class         = var.instance_class
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  username                = var.dbuser
  password                = var.dbpassword
  skip_final_snapshot     = true
  backup_retention_period = 1
}

resource "aws_db_instance" "replica" {
  identifier_prefix    = "db-replica-"
  replicate_source_db  = aws_db_instance.primary.identifier
  instance_class        = var.instance_class
  skip_final_snapshot   = true
}
