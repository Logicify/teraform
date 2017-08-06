#cloud-config
write_files:
- path: /usr/bin/install-unix-tools
  encoding: b64
  content: ${configuration_script}
  owner: root:root
  permissions: '0755'
- path: /etc/dive-in-docker.conf
  content: elasticsearch
- path: /etc/ecs/ecs.config
  content: |
    ECS_CLUSTER=${cluster_name}
    ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","syslog","journald","gelf","awslogs"]
    ECS_INSTANCE_ATTRIBUTES={"group": "${instance_group}", "cluster_role": "${cluster_role}"}
- path: /etc/sysctl.d/01-elasticsearch.conf
  content: |
    vm.max_map_count = 262144
- path: /etc/elasticsearch/config/elasticsearch.yaml
  encoding: b64
  content: ${elasticsearch_config}
- path: /etc/elasticsearch/config/jvm.options
  encoding: b64
  content: ${jvm_config}
- path: /etc/elasticsearch/config/log4j2.properties
  encoding: b64
  content: ${log4j_config}
- path: /etc/rsyslog.d/31-elasticsearch.conf
  content: |
    :syslogtag, startswith, "elasticsearch" /var/log/elasticsearch.log
runcmd:
  - [ cloud-init-per, once, "install-unix-tools", "install-unix-tools", "full"]
  - [ cloud-init-per, once, "set-hostname", "aws-set-hostname", "${host_name}", "-s"]
  - [ cloud-init-per, once, "restart-syslog", "service", "rsyslog", "restart" ]
  - [ cloud-init-per, once, "read-custom-syslog", "sysctl", "-p", "/etc/sysctl.d/01-elasticsearch.conf"]
  - [ cloud-init-per, once, "docker-stop", "service", "docker", "stop"]
  - [ cloud-init-per, once, "mount-ebs", "mount-ebs", "${volume_device}", "${volume_path}"]
  - [ cloud-init-per, once, "grant-permissions", "chmod", "0777", "-R", "${volume_path}"]
  - [ cloud-init-per, once, "create-plugins-dir", "mkdir", "/etc/elasticsearch/config/plugins"]
  - [ cloud-init-per, once, "docker-start", "service", "docker", "start"]
  - [ cloud-init-per, once, "start-ecs", "start", "ecs"]