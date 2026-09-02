module "app_vpc"{
    source =  "./modules/vpc"

    vpc_name = "app-vpc"
    vpc_cidr = var.app_vpc_cidr
    

}