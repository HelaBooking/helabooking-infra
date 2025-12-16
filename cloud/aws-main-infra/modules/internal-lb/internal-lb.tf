################################ Internal LB Module Resources ##############################
resource "aws_lb" "kube_api_nlb" {
  name               = "${var.project_name}-kube-api-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnets

  enable_cross_zone_load_balancing = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-kube-api-nlb"
  })
}

resource "aws_lb_target_group" "kube_api_tg" {
  name     = "${var.project_name}-kube-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  # Critical for NLB health checks on K8s API
  health_check {
    protocol = "TCP"
    port     = 6443
    interval = 30
    timeout  = 10
  }

  tags = var.common_tags
}

resource "aws_lb_listener" "kube_api_nlb_lr" {
  load_balancer_arn = aws_lb.kube_api_nlb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_api_tg.arn
  }
}
