variable "app_name"              { type = string }
variable "environment"           { type = string }
variable "subnet_ids"            { type = list(string) }
variable "db_sg_id"              { type = string }
variable "multi_az"              { type = bool   default = false }
variable "backup_retention_days" { type = number default = 1 }