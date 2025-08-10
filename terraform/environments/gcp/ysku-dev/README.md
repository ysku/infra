# ysku-dev Environment - VPC Configuration

This Terraform configuration sets up the development environment for the ysku project on Google Cloud Platform.

## Infrastructure Overview

### VPC Network
- **Network Name**: `voice-assistant`
- **Subnet**: `voice-assistant-subnet-1`
- **IP Range**: `10.0.1.0/24`
- **Region**: `asia-northeast1`
- **Zone**: `asia-northeast1-a`

### Firewall Rules
- **SSH Access**: Port 22 open to `0.0.0.0/0` for instances with `ssh-allowed` tag
- **HTTP/HTTPS**: Ports 80, 443 open to `0.0.0.0/0` for instances with `web-server` tag
- **WebRTC**: TCP 8000, UDP 10000-20000 for instances with `webrtc-server` tag
- **TURN Server**: TCP 3478,5349, UDP 3478,49152-65535 for instances with `turn-server` tag
- **Twilio WebRTC**: UDP 3478,10000-60000 for instances with `twilio-webrtc` tag

### Compute Engine Instance
- **Instance Name**: `voice-assistant-1`
- **Machine Type**: `e2-micro` (configurable via `machine_type` variable)
- **OS Image**: Ubuntu 24.04 LTS
- **Disk**: 10GB standard persistent disk
- **Network**: Attached to the VPC with static public IP address
- **Public Access**: Static external IP address assigned for internet access
- **Tags**: `ssh-allowed`, `web-server`, `webrtc-server`, `turn-server`, `twilio-webrtc`
- **Startup Script**: Installs Docker Engine, Docker Compose, Nginx, and Certbot automatically

## Required Variables

Set these variables in `terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
repositories = ["your-github-repo"]
```

Optional variables with defaults:
- `region` = `"asia-northeast1"`
- `zone` = `"asia-northeast1-a"`
- `machine_type` = `"e2-micro"`

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Access

### SSH Access
Connect to the instance using:
```bash
gcloud compute ssh voice-assistant-1 --zone=asia-northeast1-a
```

### Web Access
The instance has a static public IP address and runs Nginx. You can access it via:
- **HTTP**: `http://<static-external-ip>`
- **HTTPS**: `https://<static-external-ip>` (if SSL is configured)

To get the static external IP address:
```bash
terraform output voice_assistant_external_ip
```

Or using gcloud:
```bash
gcloud compute addresses describe voice-assistant-static-ip --region=asia-northeast1 --format="get(address)"
```

### SSL Certificate Setup
Certbot is pre-installed for SSL certificate management. To obtain a certificate:
```bash
sudo certbot --nginx -d your-domain.com
```

For automatic renewal, certbot creates a systemd timer by default.