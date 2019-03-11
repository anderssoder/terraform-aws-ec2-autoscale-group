module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.1.6"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

resource "aws_launch_template" "default" {
  count = "${var.enabled == "true" ? 1 : 0}"

  name_prefix                          = "${format("%s%s", module.label.id, var.delimiter)}"
  block_device_mappings                = ["${var.block_device_mappings}"]
  credit_specification                 = ["${var.credit_specification}"]
  disable_api_termination              = "${var.disable_api_termination}"
  ebs_optimized                        = "${var.ebs_optimized}"
  elastic_gpu_specifications           = ["${var.elastic_gpu_specifications}"]
  image_id                             = "${var.image_id}"
  instance_initiated_shutdown_behavior = "${var.instance_initiated_shutdown_behavior}"
  instance_market_options              = ["${var.instance_market_options }"]
  instance_type                        = "${var.instance_type}"
  key_name                             = "${var.key_name}"
  placement                            = ["${var.placement}"]
  user_data                            = "${var.user_data_base64}"

  iam_instance_profile {
    name = "${var.iam_instance_profile_name}"
  }

  monitoring {
    enabled = "${var.enable_monitoring}"
  }

  # https://github.com/terraform-providers/terraform-provider-aws/issues/4570
  network_interfaces {
    description                 = "${module.label.id}"
    device_index                = 0
    associate_public_ip_address = "${var.associate_public_ip_address}"
    delete_on_termination       = true
    security_groups             = ["${var.security_group_ids}"]
  }

  tag_specifications {
    resource_type = "volume"
    tags          = "${module.label.tags}"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = "${module.label.tags}"
  }

  tags = "${module.label.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

data "null_data_source" "tags_as_list_of_maps" {
  count = "${var.enabled == "true" ? length(keys(var.tags)) : 0}"

  inputs = "${map(
    "key", "${element(keys(var.tags), count.index)}",
    "value", "${element(values(var.tags), count.index)}",
    "propagate_at_launch", true
  )}"
}

resource "aws_cloudformation_stack" "default" {
  count = "${var.enabled == "true" ? 1 : 0}"

  name = "terraform-${format("%s%s", module.label.id, var.delimiter)}"
  tags = ["${data.null_data_source.tags_as_list_of_maps.*.outputs}"]

  template_body = <<STACK
Description: "${var.cfn_stack_description}"
Resources:
  ASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
    AutoScalingGroupName: "${format("%s%s", module.label.id, var.delimiter)}"
      VPCZoneIdentifier: ["${join("\",\"", var.subnet_ids)}"]
      LaunchTemplate:
        LaunchTemplateId: "${join("", aws_launch_template.default.*.id)}"
        Version: "${aws_launch_template.default.latest_version}"
      MinSize: "${var.min_size}"
      MaxSize: "${var.max_size}"
      LoadBalancerNames: ["${join("\",\"", var.load_balancers)}"]
      HealthCheckType: "${var.health_check_type}"
      HealthCheckGracePeriod: "${var.health_check_grace_period}"
      TerminationPolicies: ["${join("\",\"", var.termination_policies)}"]
      ServiceLinkedRoleARN: "${var.service_linked_role_arn}"
      MetricsCollection:
        Granularity: "${var.metrics_granularity}"
        Metrics: ["${join("\",\"", var.enabled_metrics)}"]
      PlacementGroup: "${var.placement_group}"
      TargetGroupARNs: "${join("\",\"", var.target_group_arns)}"
      Cooldown: "${var.default_cooldown}"
    CreationPolicy:
      AutoScalingCreationPolicy:
        MinSuccessfulInstancesPercent: "${var.cfn_creation_policy_min_successful_instances_percent}"
      ResourceSignal:
        Count: "${var.cfn_signal_count}"
        Timeout: "${var.cfn_creation_policy_timeout}"
    UpdatePolicy:
      # Ignore differences in group size properties caused by scheduled actions
      AutoScalingScheduledAction:
        IgnoreUnmodifiedGroupSizeProperties: "${var.cfn_update_policy_ignore_unmodified_group_size_properties}"
      AutoScalingRollingUpdate:
        MaxBatchSize: "${var.cfn_update_policy_max_batch_size}"
        MinInstancesInService: "${var.min_size}"
        MinSuccessfulInstancesPercent: "${var.cfn_update_policy_min_successful_instances_percent}"
        PauseTime: "${var.cfn_update_policy_pause_time}"
        SuspendProcesses: ["${join("\",\"", var.cfn_update_policy_suspended_processes)}"]
        WaitOnResourceSignals: "${var.cfn_update_policy_wait_on_resource_signals}"
    DeletionPolicy: "${var.cfn_deletion_policy}"
Outputs:
  AsgName:
    Description: The Auto Scaling Group name
    Value: !Ref ASG
  STACK
}

data "aws_autoscaling_group" "default" {
  name       = "${aws_cloudformation_stack.default.outputs["AsgName"]}"
  depends_on = ["aws_cloudformation_stack.default"]
}
