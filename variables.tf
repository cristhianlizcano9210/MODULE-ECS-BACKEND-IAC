variable "family_name" {
  description = "The tasks' family name"
  type        = string
}

variable "task_network_mode" {
  description = "The task network mode"
  type        = string
  default     = "awsvpc"
}

variable "task_role_arn" {
  description = "The role the task will use to launch itself"
  type        = string
  default     = ""
}

variable "task_execution_role_arn" {
  description = "The role the task will use to run"
  type        = string
  default     = ""
}

variable "service_name" {
  description = "The service's name"
  type        = string
}

variable "service_cluster_name" {
  description = "The cluster the service will be allocated"
  type        = string
}

variable "service_cluster_arn" {
  description = "The cluster the service will be allocated"
  type        = string
}


variable "service_network_configuration" {
  description = "The service's network configuration"
  type        = any
}

variable "ecr_name" {
  description = "The name for the docker repository for your service"
  type        = string
}

variable "task_tags" {
  description = "The task definition's tags"
  type        = map(string)
  default     = {}
}

variable "service_tags" {
  description = "The service's tags"
  type        = map(string)
  default     = {}
}

variable "container_definitions" {
  description = "Full compiled JSON with the container definitions for the task family"
  type        = string
}

variable "task_memory" {
  description = "The memory will be assigned to the entire task"
  type        = number
  default     = 512
}

variable "lb_listeners" {
  description = "Specify the load balancers listeners you want to create for the service"
  type        = any
  default     = []
}

variable "target_groups" {
  description = "Specify the target groups configurations you want to create"
  type        = any
  default     = []
}

variable "vpc_id" {
  description = "Your VPC ID"
  type        = string
}

variable "certificate_arn" {
  description = "Certificate to be associated to the LB listener"
  type        = string
  default     = ""
}

variable "service_ordered_placement_strategy" {
  type        = any
  description = "Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence"
  default     = []
}

variable "platform_version" {
  type        = string
  description = "version for platform"
  default     = "1.4.0"
}

variable "security_group" {
  type        = any
  description = "Ingress and egress rules for the service"
  default     = {}
}

variable "service_health_check_grace_period_seconds" {
  type        = number
  description = "Time in seconds to wait to start checking the service's health"
  default     = 10
}

variable "service_create_autoscaling_config" {
  description = "Whether to create an autoscaling configuration for the ECS service"
  type        = bool
  default     = false
}

variable "service_autoscaling_target_max_capacity" {
  description = "The max capacity of task for your ECS service autoscaling configuration"
  type        = number
  default     = 4
}

variable "service_autoscaling_target_min_capacity" {
  description = "The min capacity of task for your ECS service autoscaling configuration"
  type        = number
  default     = 1
}

variable "service_autoscaling_average_mem_utilization_trigger" {
  description = "The percent of average memory utilization to scale up"
  type        = number
  default     = 80
}

variable "service_autoscaling_average_cpu_utilization_trigger" {
  description = "The percent of average cpu utilization to scale up"
  type        = number
  default     = 60
}

variable "ecr_lifepolicy" {
  description = "The policy document. This is a JSON formatted string"
  type        = any
  default     = null
}

variable "ecr_create_life_policy" {
  description = "Whether to create the ECR policy"
  type        = bool
  default     = false
}

variable "create_ecs" {
  description = "Whether to create the ECS"
  type        = bool
  default     = true
}

variable "create_role" {
  type        = bool
  default     = false
  description = "This variable allows you to create rol for ecs"
}

variable "custom_role_policy_arns" {
  type        = list(string)
  default     = [""]
  description = "List of ARNs of IAM policies to attach to IAM role"
}

variable "service_circuit_breaker" {
  description = "Specifies whether to enable deployment circuit breaker"
  type        = bool
  default     = false
}

variable "service_deployment_maximum_percent" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment"
  type        = number
  default     = 100
}

variable "service_deployment_minimum_healthy_percent" {
  description = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment"
  type        = number
  default     = 0
}