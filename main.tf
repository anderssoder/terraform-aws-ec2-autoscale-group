module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.2.1"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("asg")))}"]
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

data "template_file" "userdata" {
  #count    = "${var.enabled == "true" ? 1 : 0}"
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    stack_name = "terraform-${module.label.id}"
    resource   = "ASG"
    region     = "${var.cfn_region}"
  }
}

# append extra user data
data "template_cloudinit_config" "append_userdata" {
  #count = "${var.enabled == "true" ? 1 : 0}"

  part {
    filename = "base_userdata.sh"
    content  = "${base64decode(var.user_data_base64)}"
  }

  # append 
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata.rendered}"
  }
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
  user_data                            = "${data.template_cloudinit_config.append_userdata.rendered}"

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

  name = "terraform-${module.label.id}"
  tags = "${data.null_data_source.tags_as_list_of_maps.*.outputs}"

  parameters = {
    LoadBalancerNames     = "${join(",", var.load_balancers)}"
    TargetGroupARNs       = "${join(",", var.target_group_arns)}"
    ServiceLinkedRoleARN  = "${var.service_linked_role_arn}"
    PlacementGroup        = "${var.placement_group}"
    IgnoreUnmodified      = "${var.cfn_update_policy_ignore_unmodified_group_size_properties}"
    WaitOnResourceSignals = "${var.cfn_update_policy_wait_on_resource_signals}"
    NodeDrainEnabled      = "${var.node_drain_enabled}"
  }

  on_failure = "${var.cfn_stack_on_failure}"

  template_body = <<STACK
Description: "${var.cfn_stack_description}"
Parameters:
  LoadBalancerNames:
    Type: CommaDelimitedList
    Description: The load balancer names for the ASG
    Default: ""
  TargetGroupARNs:
    Type: CommaDelimitedList
    Description: Target group ARNs for the ASG
    Default: ""
  ServiceLinkedRoleARN:
    Type: String
    Description: ARN of the role the ASG uses to call other AWS services with
    Default: ""
  PlacementGroup:
    Type: String
    Description: The name of an existing cluster placement group into which you want to launch your instances.
    Default: ""
  IgnoreUnmodified:
    Type: Number
    Default: 0
  WaitOnResourceSignals:
    Type: Number
    Default: 0
  NodeDrainEnabled:
    Type: Number
    Default: 0
Conditions:
  DrainerEnabled: !Equals [ !Ref NodeDrainEnabled, 1]
  HasLoadBalancers: !Not [ !Equals [ !Join [ "", !Ref LoadBalancerNames], ""]]
  HasTargetGroupARNs: !Not [ !Equals [ !Join [ "", !Ref TargetGroupARNs], ""]]
  HasServiceLinkedRoleARN: !Not [ !Equals [ !Ref ServiceLinkedRoleARN, ""]]
  HasPlacementGroup: !Not [ !Equals [ !Ref PlacementGroup, ""]]
  IsIgnoreUnmodified: !Equals [ !Ref IgnoreUnmodified, 1]
  IsWaitOnResourceSignals: !Equals [ !Ref WaitOnResourceSignals, 1]
Resources:
  ASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: "${module.label.id}"
      VPCZoneIdentifier: ["${join("\",\"", var.subnet_ids)}"]
      LaunchTemplate:
        LaunchTemplateId: "${join("", aws_launch_template.default.*.id)}"
        Version: "${aws_launch_template.default.latest_version}"
      MinSize: "${var.min_size}"
      MaxSize: "${var.max_size}"
      LoadBalancerNames: 
        !If [HasLoadBalancers, !Ref LoadBalancerNames, !Ref "AWS::NoValue"]
      HealthCheckType: "${var.health_check_type}"
      HealthCheckGracePeriod: "${var.health_check_grace_period}"
      TerminationPolicies: ["${join("\",\"", var.termination_policies)}"]
      ServiceLinkedRoleARN:
        !If [HasServiceLinkedRoleARN, !Ref ServiceLinkedRoleARN, !Ref "AWS::NoValue"]
      MetricsCollection:
        -
          Granularity: "${var.metrics_granularity}"
          Metrics: ["${join("\",\"", var.enabled_metrics)}"]
      PlacementGroup:
        !If [HasPlacementGroup, !Ref PlacementGroup, !Ref "AWS::NoValue"]
      TargetGroupARNs:
        !If [HasTargetGroupARNs, !Ref TargetGroupARNs, !Ref "AWS::NoValue"]
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
        IgnoreUnmodifiedGroupSizeProperties: 
          !If [IsIgnoreUnmodified, true, false]
      AutoScalingRollingUpdate:
        MaxBatchSize: "${var.cfn_update_policy_max_batch_size}"
        MinInstancesInService: "${var.min_size}"
        MinSuccessfulInstancesPercent: "${var.cfn_update_policy_min_successful_instances_percent}"
        PauseTime: "${var.cfn_update_policy_pause_time}"
        SuspendProcesses: ["${join("\",\"", var.cfn_update_policy_suspended_processes)}"]
        WaitOnResourceSignals:
          !If [IsWaitOnResourceSignals, true, false]
    DeletionPolicy: "${var.cfn_deletion_policy}"
  TerminateHook:
    Condition: DrainerEnabled 
    Type: AWS::AutoScaling::LifecycleHook
    Properties:
      AutoScalingGroupName: !Ref ASG
      DefaultResult: CONTINUE
      HeartbeatTimeout: "${var.drainer_heartbeat_timeout}"
      LifecycleTransition: "autoscaling:EC2_INSTANCE_TERMINATING"
      LifecycleHookName: "nodedrainer"
      NotificationTargetARN: "${join("", aws_sqs_queue.default.*.arn)}"
      RoleARN: "${join("", aws_iam_role.queue_role.*.arn)}"
Outputs:
  AsgName:
    Value: !Ref ASG
  STACK
}

data "aws_autoscaling_group" "default" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  name       = "${aws_cloudformation_stack.default.outputs["AsgName"]}"
  depends_on = ["aws_cloudformation_stack.default"]
}

resource "aws_sqs_queue" "default" {
  count = "${var.enabled == "true" && var.node_drain_enabled == "true" ? 1 : 0}"
  name  = "${module.label.id}-queue"
}

data "aws_iam_policy_document" "assume_role" {
  count = "${var.enabled == "true" && var.node_drain_enabled == "true" ? 1 : 0}"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals = {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "queue_role" {
  count              = "${var.enabled == "true" && var.node_drain_enabled == "true" ? 1 : 0}"
  name               = "${module.label.id}-queue-role"
  assume_role_policy = "${join("", data.aws_iam_policy_document.assume_role.*.json)}"
}

resource "aws_iam_policy" "queue" {
  count = "${var.enabled == "true" && var.node_drain_enabled == "true" ? 1 : 0}"
  name  = "${module.label.id}-queue-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
    "Effect": "Allow",
    "Action": [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ],
    "Resource": { "${aws_sqs_queue.default.*.arn}" }
  } ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = "${var.enabled == "true" && var.node_drain_enabled == "true" ? 1 : 0}"
  role       = "${join("", aws_iam_role.queue_role.*.name)}"
  policy_arn = "${join("", aws_iam_policy.queue.*.arn)}"
}
