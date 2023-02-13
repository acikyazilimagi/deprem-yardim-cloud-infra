locals {
  aws_managed_waf_rules = [
    "AWSManagedRulesAmazonIpReputationList",
    "AWSManagedRulesAnonymousIpList",
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesLinuxRuleSet",
    "AWSManagedRulesPHPRuleSet",
    "AWSManagedRulesAdminProtectionRuleSet"
  ]
}

resource "aws_wafv2_ip_set" "trusted_ip" {
  name               = "trusted-ip"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["188.119.10.85/32"]
}

resource "aws_wafv2_web_acl" "generic" {
  name        = "waf-generic"
  description = "waf for all resources"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 0

    statement {
      rate_based_statement {
        limit              = 300
        aggregate_key_type = "FORWARDED_IP"
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.trusted_ip.arn
                ip_set_forwarded_ip_config {
                  header_name       = "CF-Connecting-IP"
                  fallback_behavior = "MATCH"
                  position          = "ANY"
                }
              }
            }
          }
        }

        forwarded_ip_config {
          header_name       = "CF-Connecting-IP"
          fallback_behavior = "MATCH"
        }
      }
    }

    action {
      captcha {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = local.aws_managed_waf_rules

    content {
      name     = "AWS-${rule.value}"
      priority = rule.key + 1

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-${rule.value}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-generic"
    sampled_requests_enabled   = true
  }
}
