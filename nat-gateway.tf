data "aws_eip" "nat-a-eip" {
  tags = {
    Name = "gw NAT-A"
  }
}

resource "aws_nat_gateway" "nat-a-gw" {
  allocation_id = data.aws_eip.nat-a-eip.id
  subnet_id     = aws_subnet.public-subnet-a.id

  tags = {
    Name = "nat gateway A"
  }

}
