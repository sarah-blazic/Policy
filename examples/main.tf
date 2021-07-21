provider "panos" {
  hostname = var.hostname
  username = var.user
  password = var.password
}

module "policy" {
  source  = "sarah-blazic/policy/panos"
  version = "0.1.2"

  tags_file       = try(jsondecode(file("./files/json/tags.json")), {})
  services_file   = try(jsondecode(file("./files/json/services.json")), {})
  addr_group_file = try(jsondecode(file("./files/json/addr_group.json")), {})
  addr_obj_file   = try(jsondecode(file("./files/json/addr_obj.json")), {})
  sec_file        = try(jsondecode(file("./files/json/sec_policy.json")), {})
  nat_file        = try(jsondecode(file("./files/json/nat.json")), {})
}


