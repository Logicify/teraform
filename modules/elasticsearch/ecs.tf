data "template_file" "elasticsearch_master_config" {
  template = "${file("${path.module}/resources/elasticsearch.json")}"
  vars {
    container_name = "elasticsearch-master"
    elasticsearch_version = "${var.elasticsearch_version}"
    memory = "${var.container_memory_limit}"
    node_name = "${var.verbose_name}-elasticsearch-master"
    elasticsearch-cluster-name = "${var.elasticsearch_cluster_name}"
    volume_name = "elasticseach-data"
    native_transport_port = 9300
    http_service_port = 9200
    extra-options = ""
  }
}

