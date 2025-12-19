# Templates to be used for Helm Charts
resource "helm_release" "helm_chart_template" {
  name       = var.chart_name
  repository = var.chart_repository
  chart      = var.chart
  namespace  = var.namespace
  version    = var.chart_version

  timeout         = var.timeout_seconds
  wait            = var.wait
  atomic          = var.atomic
  cleanup_on_fail = var.cleanup_on_fail

  values = [
    var.custom_values
  ]
  dynamic "set" {
    for_each = {
      for item in var.set_values : item.name => item if lookup(item, "value_list", null) == null
    }
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  # This block will ONLY iterate over items that have a 'value_list' (list).
  dynamic "set_list" {
    for_each = {
      for item in var.set_values : item.name => item if lookup(item, "value_list", null) != null
    }
    content {
      name  = set_list.value.name
      value = set_list.value.value_list
    }
  }

  depends_on = [var.depends_on_resource]
}
