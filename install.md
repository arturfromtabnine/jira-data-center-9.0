# GCP + Docker compose

1. Create a Compute Engine instance:

```
gcloud compute instances create jira-cluster \
 --project tabnine-staging \
 --image-family ubuntu-2004-lts \
 --image-project ubuntu-os-cloud \
 --machine-type e2-standard-4 \
 --boot-disk-size 100GB \
 --zone us-central1-a
```

2. SSH into the instance and install Docker and Docker Compose:

```
gcloud compute ssh jira-cluster --project tabnine-staging --zone us-central1-a

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

3. Transfer your project files:

```
sudo apt-get install -y git
git clone https://github.com/arturfromtabnine/jira-data-center-9.0.git ~/jira-cluster
```

4. Create the required directories:

```
sudo mkdir -p /opt/jira-cluster/9.0.0/jira-home-node1
sudo mkdir -p /opt/jira-cluster/9.0.0/jira-home-shared
sudo chown -R $USER:$USER /opt/jira-cluster
```

5. Configure firewall rules:

```
gcloud compute --project tabnine-staging firewall-rules create allow-jira \
  --allow tcp:443,tcp:1900 \
  --target-tags=jira-cluster \
  --description="Allow incoming traffic for Jira"

gcloud compute instances add-tags jira-cluster --project tabnine-staging --tags jira-cluster --zone us-central1-a
```

6. Generate a new self-signed certificate that includes the IP address:

```
cd ~/jira-cluster/9.0.0/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -subj "/CN=35.63.112.151" -addext "subjectAltName = IP:35.63.112.151"
```

7. Run the Docker Compose file:

```
gcloud compute ssh jira-cluster --project tabnine-staging --zone us-central1-a

cd ~/jira-cluster/9.0.0

sudo docker-compose -f docker-compose-one-node.yml up
```

# GCP + Terraform

1. Initialize Terraform:

`terraform init`

2. Plan changes:

`terraform plan`

3. Apply changes:

`terraform apply`

By following these steps, Terraform will create all necessary resources in Google Cloud without you having to manually create anything in gcloud. Terraform will:

1. Create the Compute Engine instance
2. Set up the firewall rules
3. Install all necessary software via the startup script
