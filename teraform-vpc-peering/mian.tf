module "app_vpc"{
    source = "./modules/vpc"

    vpc_name = "app-vpc"
    vpc_cidr = var.app_vpc_cidr
    subnet_cidr = var.app_subnet_cidr
}

module "database_vpc"{
    source = "./modules/vpc"
    
    vpc_name = "database-vpc"
    vpc_cidr = var.database_vpc_cidr
    subnet_cidr = var.database_subnet_cidr
}

module "vpc_peering" {
    source = "./modules/vpc-peering"

    requester_vpc_id = module.app_vpc.vpc_id
    accepter_vpc_id  = module.database_vpc.vpc_id

    requester_route_table_id = module.app_vpc.route_table_id
    accepter_route_table_id  = module.database_vpc.route_table_id

    requester_vpc_cidr = var.app_vpc_cidr
    accepter_vpc_cidr  = var.database_vpc_cidr

    peering_name = "app-to-database-peering"
}