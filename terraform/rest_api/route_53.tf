locals {
  certificate_domain = "*.${var.domain_name}"
}

##################################################################################
# Load dependent information

data "aws_route53_zone" "zone" {
  name = var.domain_name
}

data "aws_acm_certificate" "cert" {
  domain   = local.certificate_domain
  statuses = ["ISSUED"]
}

##################################################################################

resource "aws_api_gateway_domain_name" "main" {
  domain_name = var.api_domain_name

  regional_certificate_arn  = "${data.aws_acm_certificate.cert.arn}"

  endpoint_configuration {
    types = [ "REGIONAL" ]
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_deployment.main.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
}

##################################################################################

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = aws_api_gateway_domain_name.main.domain_name
  type    = "A"

  alias {
      name                   = "${aws_api_gateway_domain_name.main.regional_domain_name}"
      zone_id                = "${aws_api_gateway_domain_name.main.regional_zone_id}"
      evaluate_target_health = false
  }
}
