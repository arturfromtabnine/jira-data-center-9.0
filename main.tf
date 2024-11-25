terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  # No credentials specified here - it will use ADC
}

resource "google_compute_instance" "jira_cluster_test" {
  name         = var.name
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 100
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = [var.name]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common git
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    git clone https://github.com/arturfromtabnine/jira-data-center-9.0.git /home/$USER/jira-cluster
    mkdir -p /opt/jira-cluster/9.0.0/jira-home-node1
    mkdir -p /opt/jira-cluster/9.0.0/jira-home-shared
    chown -R 2001:2001 /opt/jira-cluster/9.0.0/jira-home-node1
    chown -R 2001:2001 /opt/jira-cluster/9.0.0/jira-home-shared
    chmod -R 750 /opt/jira-cluster/9.0.0/jira-home-node1
    chmod -R 750 /opt/jira-cluster/9.0.0/jira-home-shared
    chown -R $USER:$USER /opt/jira-cluster

    mkdir -p /home/$USER/jira-cluster/9.0.0/certs
    cd /home/$USER/jira-cluster/9.0.0/certs
    INSTANCE_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -subj "/CN=$INSTANCE_IP" -addext "subjectAltName = IP:$INSTANCE_IP"
    chown -R $USER:$USER /home/$USER/jira-cluster/9.0.0/certs

    cd /home/$USER/jira-cluster
    docker-compose -f docker-compose-one-node.yml up -d
  EOF
}

resource "google_compute_firewall" "allow_jira" {
  name    = var.jira_firewall
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443", "1900"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.name]
}

output "instance_ip" {
  value = google_compute_instance.jira_cluster_test.network_interface[0].access_config[0].nat_ip
}