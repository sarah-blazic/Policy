locals {
  sec_pol_f    = jsondecode(file("ex3_sec_policy.json"))
  nat_f        = jsondecode(file("ex1_nat.json"))

}

//module "tags_mod" {
//  source = "./modules/tags"
////  tags_file = var.tags_f
//}

resource "panos_panorama_administrative_tag" "this" {
  for_each = {for tag in jsondecode(file("tags.json")): tag.name => tag }

  name          = each.key
  color         = try(each.value.color, null)
  comment       = try(each.value.comment, null)
  device_group  = try(each.value.device_group, "shared")
}

//module "addr_mod" {
//  source = "./modules/address"
////  addr_obj_file = var.addr_obj_f
////  addr_group_file = var.addr_group_f
//}

resource "panos_address_object" "this" {
  for_each = {for obj in jsondecode(file("addr_obj.json")): obj.name => obj}

  name           = each.key
  value          = lookup(each.value.value, each.value.type, null)
  type           = try(each.value.type, "ip-netmask")
  device_group   = try(each.value.device_group, "shared")
  description    = try(each.value.description, null)
  tags           = try(each.value.tags, null)
}

resource "panos_panorama_address_group" "this" {
  for_each = {for obj in jsondecode(file("addr_group.json")): obj.name => obj}

  name              = each.key
  device_group      = try(each.value.device_group, "shared")
  static_addresses  = try(each.value.static_addresses, null)
  dynamic_match     = try(each.value.dynamic_match, null)
  description       = try(each.value.description, null)
  tags              = try(each.value.tags, null)
}

module "services_mod" {
  source = "./modules/services"
//  services_file = var.services_f
}

resource "panos_panorama_security_rule_group" "this" {
  depends_on   = [panos_address_object.this, panos_panorama_administrative_tag.this]
//  depends_on   = [module.addr_mod, module.tags_mod]

  for_each = {for item in local.sec_pol_f:
  "${try(item.device_group, "shared")}_${try(item.rulebase, "pre-rulebase")}_${try(item.position_keyword, "")}_${try(item.position_reference, "")}"
  => item}
  device_group       = try(each.value.device_group, "shared")
  rulebase           = try(each.value.rulebase, "pre-rulebase")
  position_keyword   = try(each.value.position_keyword, "")
  position_reference = try(each.value.position_reference, null)

  dynamic "rule" {
    for_each = { for policy in each.value.rules : policy.name => policy }
    content {
      applications                       = lookup(rule.value, "applications", ["any"])
      categories                         = lookup(rule.value, "categories", ["any"])
      destination_addresses              = lookup(rule.value, "destination_addresses", ["any"])
      destination_zones                  = lookup(rule.value, "destination_zones", ["any"])
      hip_profiles                       = lookup(rule.value, "hip_profiles", ["any"])
      name                               = rule.value.name
      services                           = lookup(rule.value, "services", ["application-default"])
      source_addresses                   = lookup(rule.value, "source_addresses", ["any"])
      source_users                       = lookup(rule.value, "source_users", ["any"])
      source_zones                       = lookup(rule.value, "source_zones", ["any"])
      description                        = lookup(rule.value, "description", null)
      tags                               = lookup(rule.value,"tags", null)
      type                               = lookup(rule.value, "type", "universal")
      negate_source                      = lookup(rule.value, "negate_source", false)
      negate_destination                 = lookup(rule.value, "negate_destination", false)
      action                             = lookup(rule.value, "action", "allow")
      log_setting                        = lookup(rule.value, "log_setting", null)
      log_start                          = lookup(rule.value, "log_start", false)
      log_end                            = lookup(rule.value, "log_end", true)
      disabled                           = lookup(rule.value, "disabled", false)
      schedule                           = lookup(rule.value, "schedule", null)
      icmp_unreachable                   = lookup(rule.value, "icmp_unreachable", null)
      disable_server_response_inspection = lookup(rule.value, "disable_server_response_inspection", false)
      group                              = lookup(rule.value, "group", null)
      virus                              = lookup(rule.value, "virus", null)
      spyware                            = lookup(rule.value, "spyware", null)
      vulnerability                      = lookup(rule.value, "vulnerability", null)
      url_filtering                      = lookup(rule.value, "url_filtering", null)
      file_blocking                      = lookup(rule.value, "file_blocking", null)
      wildfire_analysis                  = lookup(rule.value, "wildfire_analysis", null)
      data_filtering                     = lookup(rule.value, "data_filtering", null)

      dynamic target {
        for_each = lookup(rule.value, "target", null) != null ? { for t in rule.value.target : t.serial => t } : {}

        content {
          serial    = lookup(target.value, "serial", "1234567890")
          vsys_list = lookup(target.value, "vsys_list", null)
        }
      }
      negate_target = lookup(rule.value, "negate_target", false)
    }
  }
}

resource "panos_panorama_nat_rule_group" "this" {
   for_each = {for item in local.nat_f:
  "${try(item.device_group, "shared")}_${try(item.rulebase, "pre-rulebase")}_${try(item.position_keyword, "")}_${try(item.position_reference, "")}"
  => item}
  device_group = try(each.value.device_group, "shared")
  rulebase = try(each.value.rulebase, "pre-rulebase")
  position_keyword = try(each.value.position_keyword, "")
  position_reference = try(each.value.position_reference, null)


  dynamic "rule" {
    for_each = { for policy in each.value.rules : policy.name => policy }

    content {
      name = rule.value.name
      description = lookup(rule.value, "description", null)
      tags        = lookup(rule.value,"tags", null)
      type        = lookup(rule.value, "type", "ipv4" )
      disabled    = lookup(rule.value, "disabled", false)

      dynamic target {
        for_each = lookup(rule.value, "target", null) != null ? { for t in rule.value.target : t.serial => t } : {}

        content {
          serial    = lookup(target.value, "serial", "1234567890")
          vsys_list = lookup(target.value, "vsys_list", null)
        }
      }
      negate_target = lookup(rule.value, "negate_target", false)

      original_packet {
        destination_addresses = lookup(rule.value.original_packet, "destination_addresses", ["any"] )
        destination_zone      = lookup(rule.value.original_packet, "destination_zone", "any" )
        source_addresses      = lookup(rule.value.original_packet, "source_addresses", ["any"] )
        source_zones          = lookup(rule.value.original_packet, "source_zones", ["any"])
      }
      translated_packet {
        destination {

          dynamic "static_translation" {
            for_each = rule.value.translated_packet.destination == "static_translation" ? [1] : []
            content{
              address = lookup(rule.value.translated_packet.static_translation, "address", null)
              port    = lookup(rule.value.translated_packet.static_translation, "port", null)
            }
          }

          dynamic "dynamic_translation" {
             for_each = rule.value.translated_packet.destination == "dynamic_translation" ? [1] : []
             content {
               address      = lookup(rule.value.translated_packet.dynamic_translation, "address", null)
               port         = lookup(rule.value.translated_packet.dynamic_translation, "port", null)
               distribution = lookup(rule.value.translated_packet.dynamic_translation, "distribution", null)
             }
          }
        }

        source {
          dynamic "dynamic_ip_and_port" {
            for_each = rule.value.translated_packet.source == "dynamic_ip_and_port" ? [1] : []
            content {

              dynamic "translated_address" {
                for_each = try(rule.value.translated_packet.translated_addresses, [] , null) != null ? [1] : []
                content {
                  translated_addresses = lookup(rule.value.translated_packet, "translated_addresses", null)
                }
              }

              dynamic "interface_address" {
                for_each = lookup(rule.value.translated_packet, "interface_address", null) != null ? [1] : []
                content {
                  interface  = lookup(rule.value.translated_packet.interface_address, "interface", null)
                  ip_address = lookup(rule.value.translated_packet.interface_address, "ip_address", null)
                }
              }
            }
          }

          dynamic "dynamic_ip" {
            for_each = rule.value.translated_packet.source == "dynamic_ip" ? [1] : []
            content {
              translated_addresses = lookup(rule.value.translated_packet, "translated_addresses", [] )

              dynamic "fallback" {
                for_each = lookup(rule.value.translated_packet, "fallback", null) != null ? [1] : []

                content {
                  dynamic "translated_address" {
                    for_each = try(rule.value.translated_packet.fallback.translated_addresses, [], null) != null ? [1] : []
                    content {
                      translated_addresses = lookup(rule.value.translated_packet.fallback, "translated_addresses", null)
                    }
                  }

                  dynamic "interface_address" {
                    for_each = lookup(rule.value.translated_packet.fallback, "interface_address", null) != null ? [1] : []
                    content {
                      interface  = lookup(rule.value.translated_packet.fallback.interface_address, "interface", null )
                      type       = lookup(rule.value.translated_packet.fallback.interface_address, "type", "ip")
                      ip_address = lookup(rule.value.translated_packet.fallback.interface_address, "ip_address", null )
                    }
                  }
                }
              }
            }
          }

          dynamic "static_ip" {
            for_each = rule.value.translated_packet.source == "static_ip" ? [1] : []
            content {
              translated_address = lookup(rule.value.translated_packet.static_ip,"translated_address", null)
              bi_directional     = lookup(rule.value.translated_packet.static_ip,"bi_directional", null)
            }
          }
        }
      }
    }

  }
}
