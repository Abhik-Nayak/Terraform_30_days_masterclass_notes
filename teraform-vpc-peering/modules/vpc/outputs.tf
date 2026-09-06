 output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}
 
output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}
 
output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.this.id
}
 
output "route_table_id" {
  description = "ID of the route table"
  value       = aws_route_table.this.id
}