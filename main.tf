terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("account.json")  
  project     = "playground-s-11-ac1f93ca"  
  region      = "us-central1"  # Corrigé : région, pas zone
}

resource "google_compute_network" "custom_vpc" {
  name                    = "my-custom-vpc"
  auto_create_subnetworks = false  
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.0.0/24"  # Plage IP, ajustez si nécessaire
  region        = "us-central1"
  network       = google_compute_network.custom_vpc.id
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]  
  }

  source_ranges = ["0.0.0.0/0"]  # Sécurisez en prod
  target_tags   = ["ssh-allowed"]  # Ajout : applique seulement aux tags
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-djamel"
  machine_type = "e2-medium"  # Type de machine spécifié
  zone         = "us-central1-c"  # Zone, ajustez si nécessaire

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"  
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.custom_subnet.id
    access_config {}  
  }

  metadata_startup_script = <<EOF
#!/bin/bash
apt-get update
apt-get install -y git
git clone https://github.com/Djamelchebbah/service_cloud_terraform.git /home/repo  # Ajout du chemin /home/repo
# Si repo privé : git clone https://username:VZhN13AN@github.com/... (mais utilisez un token PAT pour sécurité)
echo "Repo cloné avec succès" > /home/repo-clone-log.txt
EOF

  service_account {
    email  = "cli-service-account-1@playground-s-11-ac1f93ca.iam.gserviceaccount.com"  # Email du compte de service
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]  # Scopes pour accès GCP
  }

  tags = ["ssh-allowed"]  # Pour appliquer la règle firewall
}

# Output pour obtenir l'IP publique de la VM
output "vm_public_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}



