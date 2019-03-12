variable "namespace" {
  type        = "string"
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = "string"
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "environment" {
  type        = "string"
  default     = ""
  description = "Environment, e.g. 'testing', 'UAT'"
}

variable "name" {
  type        = "string"
  default     = "app"
  description = "Solution name, e.g. 'app' or 'cluster'"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "enabled" {
  type        = "string"
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
  default     = "true"
}

variable "image_id" {
  type        = "string"
  description = "The EC2 image ID to launch"
  default     = ""
}

variable "instance_initiated_shutdown_behavior" {
  type        = "string"
  description = "Shutdown behavior for the instances. Can be `stop` or `terminate`"
  default     = "terminate"
}

variable "instance_type" {
  type        = "string"
  description = "Instance type to launch"
}

variable "iam_instance_profile_name" {
  type        = "string"
  description = "The IAM instance profile name to associate with launched instances"
  default     = ""
}

variable "key_name" {
  type        = "string"
  description = "The SSH key name that should be used for the instance"
  default     = ""
}

variable "security_group_ids" {
  description = "A list of associated security group IDs"
  type        = "list"
  default     = []
}

variable "launch_template_version" {
  type        = "string"
  description = "Launch template version. Can be version number, `$Latest` or `$Default`"
  default     = "$Latest"
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with an instance in a VPC"
  default     = false
}

variable "user_data_base64" {
  type        = "string"
  description = "The Base64-encoded user data to provide when launching the instances"
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable/disable detailed monitoring"
  default     = true
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  default     = false
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type        = "list"
  default     = []
}

variable "instance_market_options" {
  description = "The market (purchasing) option for the instances"
  type        = "list"
  default     = []
}

variable "placement" {
  description = "The placement specifications of the instances"
  type        = "list"
  default     = []
}

variable "credit_specification" {
  description = "Customize the credit specification of the instances"
  type        = "list"
  default     = []
}

variable "elastic_gpu_specifications" {
  description = "Specifications of Elastic GPU to attach to the instances"
  type        = "list"
  default     = []
}

variable "disable_api_termination" {
  description = "If `true`, enables EC2 Instance Termination Protection"
  default     = false
}

variable "max_size" {
  description = "The maximum size of the autoscale group"
}

variable "min_size" {
  description = "The minimum size of the autoscale group"
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in"
  type        = "list"
}

variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start"
  default     = 300
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  default     = 1800
}

variable "health_check_type" {
  type        = "string"
  description = "Controls how health checking is done. Valid values are `EC2` or `ELB`"
  default     = "EC2"
}

variable "force_delete" {
  description = "Allows deleting the autoscaling group without waiting for all instances in the pool to terminate. You can force an autoscaling group to delete even if it's in the process of scaling a resource. Normally, Terraform drains all the instances before deleting the group. This bypasses that behavior and potentially leaves resources dangling"
  default     = false
}

variable "load_balancers" {
  type        = "list"
  description = "A list of elastic load balancer names to add to the autoscaling group names. Only valid for classic load balancers. For ALBs, use `target_group_arns` instead"
  default     = []
}

variable "target_group_arns" {
  type        = "list"
  description = "A list of aws_alb_target_group ARNs, for use with Application Load Balancing"
  default     = []
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are `OldestInstance`, `NewestInstance`, `OldestLaunchConfiguration`, `ClosestToNextInstanceHour`, `Default`"
  type        = "list"
  default     = ["Default"]
}

variable "placement_group" {
  type        = "string"
  description = "The name of the placement group into which you'll launch your instances, if any"
  default     = ""
}

variable "metrics_granularity" {
  type        = "string"
  description = "The granularity to associate with the metrics to collect. The only valid value is 1Minute"
  default     = "1Minute"
}

variable "enabled_metrics" {
  description = "A list of metrics to collect. The allowed values are `GroupMinSize`, `GroupMaxSize`, `GroupDesiredCapacity`, `GroupInServiceInstances`, `GroupPendingInstances`, `GroupStandbyInstances`, `GroupTerminatingInstances`, `GroupTotalInstances`"
  type        = "list"

  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]
}

variable "wait_for_capacity_timeout" {
  type        = "string"
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. Setting this to '0' causes Terraform to skip all Capacity Waiting behavior"
  default     = "10m"
}

variable "min_elb_capacity" {
  description = "Setting this causes Terraform to wait for this number of instances to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes"
  default     = 0
}

variable "wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers on both create and update operations. Takes precedence over `min_elb_capacity` behavior"
  default     = false
}

variable "protect_from_scale_in" {
  description = "Allows setting instance protection. The autoscaling group will not select instances with this setting for terminination during scale in events"
  default     = false
}

variable "service_linked_role_arn" {
  type        = "string"
  description = "The ARN of the service-linked role that the ASG will use to call other AWS services"
  default     = ""
}

variable "autoscaling_policies_enabled" {
  type        = "string"
  default     = "true"
  description = "Whether to create `aws_autoscaling_policy` and `aws_cloudwatch_metric_alarm` resources to control Auto Scaling"
}

variable "scale_up_cooldown_seconds" {
  type        = "string"
  default     = "300"
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
}

variable "scale_up_scaling_adjustment" {
  default     = 1
  description = "The number of instances by which to scale. `scale_up_adjustment_type` determines the interpretation of this number (e.g. as an absolute number or as a percentage of the existing Auto Scaling group size). A positive increment adds to the current capacity and a negative value removes from the current capacity"
}

variable "scale_up_adjustment_type" {
  type        = "string"
  default     = "ChangeInCapacity"
  description = "Specifies whether the adjustment is an absolute number or a percentage of the current capacity. Valid values are `ChangeInCapacity`, `ExactCapacity` and `PercentChangeInCapacity`"
}

variable "scale_up_policy_type" {
  type        = "string"
  default     = "SimpleScaling"
  description = "The scalling policy type, either `SimpleScaling`, `StepScaling` or `TargetTrackingScaling`"
}

variable "scale_down_cooldown_seconds" {
  type        = "string"
  default     = "300"
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
}

variable "scale_down_scaling_adjustment" {
  default     = -1
  description = "The number of instances by which to scale. `scale_down_scaling_adjustment` determines the interpretation of this number (e.g. as an absolute number or as a percentage of the existing Auto Scaling group size). A positive increment adds to the current capacity and a negative value removes from the current capacity"
}

variable "scale_down_adjustment_type" {
  type        = "string"
  default     = "ChangeInCapacity"
  description = "Specifies whether the adjustment is an absolute number or a percentage of the current capacity. Valid values are `ChangeInCapacity`, `ExactCapacity` and `PercentChangeInCapacity`"
}

variable "scale_down_policy_type" {
  type        = "string"
  default     = "SimpleScaling"
  description = "The scalling policy type, either `SimpleScaling`, `StepScaling` or `TargetTrackingScaling`"
}

variable "cpu_utilization_high_evaluation_periods" {
  type        = "string"
  default     = "2"
  description = "The number of periods over which data is compared to the specified threshold"
}

variable "cpu_utilization_high_period_seconds" {
  type        = "string"
  default     = "300"
  description = "The period in seconds over which the specified statistic is applied"
}

variable "cpu_utilization_high_threshold_percent" {
  type        = "string"
  default     = "90"
  description = "The value against which the specified statistic is compared"
}

variable "cpu_utilization_high_statistic" {
  type        = "string"
  default     = "Average"
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: `SampleCount`, `Average`, `Sum`, `Minimum`, `Maximum`"
}

variable "cpu_utilization_low_evaluation_periods" {
  type        = "string"
  default     = "2"
  description = "The number of periods over which data is compared to the specified threshold"
}

variable "cpu_utilization_low_period_seconds" {
  type        = "string"
  default     = "300"
  description = "The period in seconds over which the specified statistic is applied"
}

variable "cpu_utilization_low_threshold_percent" {
  type        = "string"
  default     = "10"
  description = "The value against which the specified statistic is compared"
}

variable "cpu_utilization_low_statistic" {
  type        = "string"
  default     = "Average"
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: `SampleCount`, `Average`, `Sum`, `Minimum`, `Maximum`"
}

variable "cfn_stack_description" {
  type        = "string"
  default     = "Managed by Terraform, do not manually modify. Creates Autoscaling group with rolling update support."
  description = "Sets the description on the Cloudformation stack."
}

variable "cfn_stack_on_failure" {
  description = "Action to be taken if stack creation fails. This must be one of: DO_NOTHING, ROLLBACK, or DELETE."
  default     = "ROLLBACK"
}

variable "cfn_signal_count" {
  description = "cfn_signal_count"
  default     = 1
}

variable "cfn_creation_policy_timeout" {
  type        = "string"
  default     = "PT10M"
  description = "The length of time that AWS CloudFormation waits for the number of signals that was specified in the Count property. The timeout period starts after AWS CloudFormation starts creating the resource, and the timeout expires no sooner than the time you specify but can occur shortly thereafter. The maximum time that you can specify is 12 hours."
}

variable "cfn_creation_policy_min_successful_instances_percent" {
  default     = 60
  description = "Specifies the percentage of instances in an Auto Scaling replacement update that must signal success for the update to succeed. You can specify a value from 0 to 100. AWS CloudFormation rounds to the nearest tenth of a percent. For example, if you update five instances with a minimum successful percentage of 50, three instances must signal success. If an instance doesn't send a signal within the time specified by the Timeout property, AWS CloudFormation assumes that the instance wasn't created."
}

variable "cfn_update_policy_min_successful_instances_percent" {
  default     = 60
  description = "description"
}

variable "cfn_update_policy_max_batch_size" {
  default     = 1
  description = "Specifies the maximum number of instances that AWS CloudFormation updates."
}

variable "cfn_update_policy_ignore_unmodified_group_size_properties" {
  default     = true
  description = "Specifies whether AWS CloudFormation ignores differences in group size properties between your current Auto Scaling group and the Auto Scaling group described in the AWS::AutoScaling::AutoScalingGroup resource of your template during a stack update. If you modify any of the group size property values in your template, AWS CloudFormation uses the modified values and updates your Auto Scaling group."
}

variable "cfn_update_policy_pause_time" {
  type        = "string"
  default     = "PT15M"
  description = "The amount of time that AWS CloudFormation pauses after making a change to a batch of instances to give those instances time to start software applications. For example, you might need to specify PauseTime when scaling up the number of instances in an Auto Scaling group."
}

variable "cfn_update_policy_suspended_processes" {
  type        = "list"
  description = "A list of processes to suspend for the AutoScaling Group. The allowed values are `Launch`, `Terminate`, `HealthCheck`, `ReplaceUnhealthy`, `AZRebalance`, `AlarmNotification`, `ScheduledActions`, `AddToLoadBalancer`. Note that if you suspend either the `Launch` or `Terminate` process types, it can prevent your autoscaling group from functioning properly."
  default     = ["HealthCheck", "ReplaceUnhealthy", "AZRebalance", "AlarmNotification", "ScheduledActions"]
}

variable "cfn_update_policy_wait_on_resource_signals" {
  description = "Specifies whether the Auto Scaling group waits on signals from new instances during an update. Use this property to ensure that instances have completed installing and configuring applications before the Auto Scaling group update proceeds."
  default     = true
}

variable "cfn_deletion_policy" {
  type        = "string"
  description = "With the DeletionPolicy attribute you can preserve or (in some cases) backup a resource when its stack is deleted. You specify a DeletionPolicy attribute for each resource that you want to control. If a resource has no DeletionPolicy attribute, AWS CloudFormation deletes the resource by default. Allowed values: `Delete`, `Retain`, `Snapshot`"
  default     = "Retain"
}

variable "region" {
  default = "eu-central-1"
}
