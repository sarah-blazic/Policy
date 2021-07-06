#antivirus
variable "antivirus_file" {
  type        = string
  description = "Path to JSON file that will supply the proper parameters to create antivirus profiles."
  default     = "optional"

  validation {
    condition     = var.antivirus_file == "optional" || (fileexists(var.antivirus_file) && (can(jsondecode(file(var.antivirus_file))) || can(yamldecode(file(var.antivirus_file)))))
    error_message = "Not a valid JSON/YAML file to read."
  }
}

#file blocking
variable "file_blocking_file" {
  type        = string
  description = "Path to JSON file that will supply the proper parameters to create file blocking profiles."
  default     = "optional"

  validation {
    condition     = var.file_blocking_file == "optional" || (fileexists(var.file_blocking_file) && (can(jsondecode(file(var.file_blocking_file))) || can(yamldecode(file(var.file_blocking_file)))))
    error_message = "Not a valid JSON/YAML file to read."
  }
}

#wildfire analysis
variable "wildfire_file" {
  type        = string
  description = "Path to JSON file that will supply the proper parameters to create wildfire analysis profiles."
  default     = "optional"

  validation {
    condition     = var.wildfire_file == "optional" || (fileexists(var.wildfire_file) && (can(jsondecode(file(var.wildfire_file))) || can(yamldecode(file(var.wildfire_file)))))
    error_message = "Not a valid JSON/YAML file to read."
  }
}