locals {
  tags = {
    Terraform = true
  }
}

module "task_definition" {
  source = "github.com/cristhianlizcano9210/MODULE-AWS-ECS-IAC?ref=v1.0.0"

  create_task_definition  = var.create_ecs
  family_name             = var.family_name
  container_definitions   = var.container_definitions
  task_network_mode       = var.task_network_mode
  task_role_arn           = var.create_role ? module.role_ecs.this_iam_role_arn : var.task_role_arn
  task_execution_role_arn = var.create_role ? module.role_ecs.this_iam_role_arn : var.task_execution_role_arn
  task_memory             = var.task_memory

  task_tags = merge(
    local.tags,
    var.task_tags,
  )
}

module "service" {
  source = "github.com/cristhianlizcano9210/MODULE-AWS-ECS-IAC?ref=v1.0.0"

  create_service                              = var.create_ecs
  service_name                                = var.service_name
  service_task_definition                     = module.task_definition.this_task_definition_arn
  service_desired_count                       = 0
  cluster_name                                = var.service_cluster_name
  cluster_arn                                 = var.service_cluster_arn
  service_enable_ecs_managed_tags             = false
  service_ordered_placement_strategy          = var.service_ordered_placement_strategy
  service_platform_version                    = var.platform_version
  service_tags                                = merge(local.tags, var.service_tags)
  service_health_check_grace_period_seconds   = var.service_health_check_grace_period_seconds
  create_autoscaling_config                   = var.service_create_autoscaling_config
  autoscaling_target_max_capacity             = var.service_autoscaling_target_max_capacity
  autoscaling_target_min_capacity             = var.service_autoscaling_target_min_capacity
  autoscaling_average_mem_utilization_trigger = var.service_autoscaling_average_mem_utilization_trigger
  autoscaling_average_cpu_utilization_trigger = var.service_autoscaling_average_cpu_utilization_trigger
  enable_circuit_breaker                      = var.service_circuit_breaker
  service_deployment_maximum_percent          = var.service_deployment_maximum_percent
  service_deployment_minimum_healthy_percent  = var.service_deployment_minimum_healthy_percent

  service_network_configuration = {
    subnets          = lookup(var.service_network_configuration, "subnets", [])
    security_groups  = [element(concat(aws_security_group.this.*.id, [""]), 0)]
    assign_public_ip = lookup(var.service_network_configuration, "assign_public_ip", false)
  }

  service_load_balancers = flatten([
    for lb_listener in var.lb_listeners : {
      target_group_arn = var.create_ecs == true ? aws_lb_target_group.this[lb_listener.target_group_index].arn : ""
      container_name   = var.target_groups[lb_listener.target_group_index].container_name
      container_port   = var.target_groups[lb_listener.target_group_index].backend_port
    }
  ])
}

module "ecr" {
  source = "github.com/cristhianlizcano9210/MODULE-AWS-ECR-IAC?ref=v1.0.0"
  

  create               = var.create_ecs
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
  create_life_policy   = var.ecr_create_life_policy
  lifepolicy           = var.ecr_lifepolicy
}

resource "aws_lb_listener" "this" {
  count             = var.create_ecs && length(var.lb_listeners) > 0 ? length(var.lb_listeners) : 0
  load_balancer_arn = var.lb_listeners[count.index].lb_arn
  port              = var.lb_listeners[count.index].port
  protocol          = var.lb_listeners[count.index].protocol
  ssl_policy        = var.lb_listeners[count.index].protocol == "TLS" || var.lb_listeners[count.index].protocol == "HTTPS" ? var.lb_listeners[count.index].ssl_policy : null
  certificate_arn   = var.lb_listeners[count.index].protocol == "TLS" || var.lb_listeners[count.index].protocol == "HTTPS" ? var.certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.lb_listeners[count.index].target_group_index].arn
  }

  depends_on = [var.lb_listeners, aws_lb_target_group.this, var.certificate_arn]
}

resource "aws_lb_target_group" "this" {
  count                = var.create_ecs && length(var.target_groups) > 0 ? length(var.target_groups) : 0
  name                 = lookup(var.target_groups[count.index], "name", null)
  name_prefix          = lookup(var.target_groups[count.index], "name_prefix", null)
  port                 = lookup(var.target_groups[count.index], "backend_port", null)
  protocol             = lookup(var.target_groups[count.index], "backend_protocol", null) != null ? upper(lookup(var.target_groups[count.index], "backend_protocol")) : null
  vpc_id               = var.vpc_id
  deregistration_delay = lookup(var.target_groups[count.index], "deregistration_delay", null)
  slow_start           = lookup(var.target_groups[count.index], "slow_start", null)
  proxy_protocol_v2    = lookup(var.target_groups[count.index], "proxy_protocol_v2", null)

  dynamic "stickiness" {
    for_each = length(keys(lookup(var.target_groups[count.index], "stickiness", {}))) == 0 ? [] : [lookup(var.target_groups[count.index], "stickiness", {})]

    content {
      enabled         = lookup(stickiness.value, "enabled", null)
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      type            = lookup(stickiness.value, "type", null)
    }
  }

  dynamic "health_check" {
    for_each = length(keys(lookup(var.target_groups[count.index], "health_check", {}))) == 0 ? [] : [lookup(var.target_groups[count.index], "health_check", {})]

    content {
      enabled             = lookup(health_check.value, "enabled", null)
      interval            = lookup(health_check.value, "interval", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      timeout             = lookup(health_check.value, "timeout", null)
      protocol            = lookup(health_check.value, "protocol", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  target_type = lookup(var.target_groups[count.index], "target_type", null)
  tags        = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  count       = var.create_ecs ? 1 : 0
  name        = var.service_name
  description = "SG for ECS service ${var.service_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.security_group.ingress) == 0 ? [] : var.security_group.ingress

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      description = ingress.value.description
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = length(var.security_group.egress) == 0 ? [] : var.security_group.egress

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      description = egress.value.description
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

module "role_ecs" {
  source = "github.com/cristhianlizcano9210/MODULE-AWS-IAM-IAC?ref=v1.0.0"

  create_role                = var.create_role
  role_requires_mfa          = false
  data_trusted_role_services = ["ecs-tasks.amazonaws.com"]
  role_name                  = "ecs-${var.service_name}"
  custom_role_policy_arns    = var.custom_role_policy_arns
}
