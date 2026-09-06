 output "app_vpc_id" {
  description = "ID of the application VPC"
  value       = module.app_vpc.vpc_id
}
 
output "database_vpc_id" {
  description = "ID of the database VPC"
  value       = module.database_vpc.vpc_id
}
 
output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = module.app_vpc.subnet_id
}
 
output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = module.database_vpc.subnet_id
}
 
output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = module.vpc_peering.peering_connection_id
}