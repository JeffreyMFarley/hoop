# :+1: to https://github.com/LukeMwila/aws-apigateway-vpc-ecs-fargate/blob/master/infra-modules/backend-environment/ecs-fargate/nlb_service.tf

resource "aws_lb" "nlb" {
  name               = "nlb-${var.name}"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "nlb_tg" {
  name        = "nlb-${var.name}-tg"
  port        = var.app_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on  = [
    aws_lb.nlb
  ]
}

# Redirect all traffic from the NLB to the target group
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.id
  port              = var.host_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.nlb_tg.id
    type             = "forward"
  }
}
