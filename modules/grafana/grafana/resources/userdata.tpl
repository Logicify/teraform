#cloud-config
write_files:
- path: /usr/bin/install-unix-tools
  encoding: b64
  content: ${configuration_script}
  owner: root:root
  permissions: '0755'
- path: /etc/dive-in-docker.conf
  content: garafana
- path: /etc/ecs/ecs.config
  content: |
    ECS_CLUSTER=${cluster_name}
    ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","syslog","journald","gelf","awslogs"]
    ECS_INSTANCE_ATTRIBUTES={"group": "${instance_group}", "cluster_role": "${cluster_role}"}
- path: /etc/rsyslog.d/31-grafana.conf
  content: |
    :syslogtag, startswith, "grafana" /var/log/grafana.log
runcmd:
  - [ cloud-init-per, once, "install-unix-tools", "install-unix-tools", "full"]
  - [ cloud-init-per, once, "set-hostname", "aws-set-hostname", "${host_name}", "-s"]
  - [ cloud-init-per, once, "restart-syslog", "service", "rsyslog", "restart" ]
  - [ cloud-init-per, once, "docker-stop", "service", "docker", "stop"]
  - [ cloud-init-per, once, "mount-ebs", "mount-ebs", "${volume_device}", "${volume_path}", "0777" ]
  - [ cloud-init-per, once, "docker-start", "service", "docker", "start"]
  - [ cloud-init-per, once, "start-ecs", "start", "ecs"]