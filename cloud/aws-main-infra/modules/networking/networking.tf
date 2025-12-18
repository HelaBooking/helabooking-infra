################################ Networking Module Resources ##############################
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, { Name = "${var.project_name}-vpc" })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags       = merge(var.common_tags, { Name = "${var.project_name}-igw" })
  depends_on = [aws_vpc.main]
}

# Subnets
# Public Subnet (Single AZ for simplicity for Bastion/VPN)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1) # 10.0.1.0/24
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name                     = "${var.project_name}-public-subnet"
    "kubernetes.io/role/elb" = "1" # Required for Public ALBs
  })
  depends_on = [aws_vpc.main]
}
# Private Subnets (Multi-AZ for K8s Workers/Masters)
resource "aws_subnet" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id
  # Creates 10.0.10.0/24, 10.0.11.0/24, etc.
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, {
    Name                                        = "${var.project_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"      # Required for Private ALBs
    "kubernetes.io/cluster/${var.project_name}" = "shared" # Required for ALB Controller discovery
  })
  depends_on = [aws_vpc.main]
}

# NAT Gateway (Required for Private Nodes to reach Internet for installation)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.project_name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id # NAT must live in Public Subnet

  tags       = merge(var.common_tags, { Name = "${var.project_name}-nat" })
  depends_on = [aws_internet_gateway.igw, aws_eip.nat, aws_subnet.public]
}

# Route Tables
# Public RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags       = merge(var.common_tags, { Name = "${var.project_name}-public-rt" })
  depends_on = [aws_subnet.public]
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
  depends_on     = [aws_route_table.public]
}
# Private RT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags       = merge(var.common_tags, { Name = "${var.project_name}-private-rt" })
  depends_on = [aws_subnet.private]
}
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
  depends_on     = [aws_route_table.private]
}
