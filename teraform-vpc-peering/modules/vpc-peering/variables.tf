variable "requester_vpc_id" {
  description = "ID of the VPC that starts the peering request"
  type        = string
}
 
 variable "accepter_vpc_id" {
  description = "ID of the VPC that accepts the peering request"
  type        = string
}
 
variable "requester_route_table_id" {
  description = "Route table ID of the requester VPC"
  type        = string
}
 
variable "accepter_route_table_id" {
  description = "Route table ID of the accepter VPC"
  type        = string
}
 
variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}
 
variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}
 
variable "peering_name" {
  description = "Name of the VPC peering connection"
  type        = string
}