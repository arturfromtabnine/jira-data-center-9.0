variable "name" {
  description = "The name of the resource"
  default     = "jira-dc"
}

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  default     = "tabnine-staging"
}

variable "region" {
  description = "The region to deploy to"
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy to"
  default     = "us-central1-a"
}

variable "jira_firewall" {
  description = "Firewall rule name"
  default     = "allow-jira-test"
}