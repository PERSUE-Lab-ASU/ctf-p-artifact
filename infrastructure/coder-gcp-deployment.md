# Coder on GCP Deployment Guide

This guide describes how to reproduce the CTF-P participant environment using
open source Coder on a Google Cloud Platform VM. In this deployment model, each
participant receives a Coder workspace backed by one Docker container running
the CTF-P challenge image.

## Overview

The deployment has four main parts:

1. A GCP VM runs Docker and the Coder server.
2. The CTF-P Docker image is built from this repository and published to a
   registry that the GCP VM can pull from.
3. A Coder template provisions one Docker workspace container per participant.
4. Optional participant setup scripts create Coder users for a study.

The participant-visible environment is container-based, not VM-per-participant,
but it is designed to feel like a Linux machine for the challenge.

## Prerequisites

- A GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- Docker installed locally or on the GCP VM
- A container registry account, such as GitHub Container Registry or Docker Hub
- Coder CLI access to the Coder server after installation

## 1. Create the GCP VM

The exact machine size depends on the expected number of participants. The
example below creates a single Ubuntu VM suitable for a small study or test
deployment.

```bash
gcloud compute instances create coder-vm \
  --zone=us-east1-c \
  --machine-type=n2d-standard-4 \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-standard \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud
```

SSH into the VM:

```bash
gcloud compute ssh coder-vm --zone=us-east1-c
```

Install Docker and basic tools:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin curl wget jq openssl
sudo usermod -aG docker "$USER"
newgrp docker
docker version
```

## 2. Install and Start Coder

Install the open source Coder CLI/server:

```bash
curl -fsSL https://coder.com/install.sh | sh
coder version
```

Start Coder:

```bash
mkdir -p ~/coder-data
cd ~/coder-data
coder server
```

Coder prints a web URL during startup. Open that URL in a browser and create the
first admin account.

For a longer-running deployment, run Coder under a process manager such as
`systemd`. The exact service setup depends on your local VM policy.

## 3. Build and Publish the CTF-P Image

From the repository root, build the challenge image:

```bash
docker build -t ghcr.io/example-org/ctf-p:latest .
```

Replace `ghcr.io/example-org/ctf-p:latest` with the image name for your own
registry or organization.

Push the image:

```bash
docker push ghcr.io/example-org/ctf-p:latest
```

On the GCP VM, verify that Docker can pull the image:

```bash
docker pull ghcr.io/example-org/ctf-p:latest
```

If the image is private, authenticate to the registry on the GCP VM before
creating participant workspaces.

## 4. Configure the Coder Template

The Coder template source is:

```text
infrastructure/coder-template/main.tf
```

Before creating the template in Coder, update the image reference in that file:

```hcl
image = "ghcr.io/example-org/ctf-p:latest"
```

Use the image tag you built and pushed in the previous step.

The template:

- creates a Coder agent
- launches the CTF-P Docker image as a participant workspace container
- starts `supervisord` inside the container
- mounts `/var/log/sessions` to a persistent host directory
- persists participant home data through a Docker volume
- labels the container with participant and workspace metadata

## 5. Create the Coder Template

On a machine logged in to your Coder instance:

```bash
coder login https://your-coder-instance.example
```

Create a local template directory and copy in the template file:

```bash
mkdir -p ~/ctf-p-template
cp infrastructure/coder-template/main.tf ~/ctf-p-template/main.tf
cd ~/ctf-p-template
coder templates create ctf-p
```

If you later update the template:

```bash
coder templates push ctf-p
```

## 6. Create Participant Users

Participant user creation is handled by:

```text
infrastructure/participant-setup/
```

Configure the environment:

```bash
cd infrastructure/participant-setup
cp env.example .env
```

Edit `.env`:

```bash
CODER_URL="https://your-coder-instance.example"
STUDY_DOMAIN="study.ctf.example.com"
```

Load the environment and create users:

```bash
source .env
coder login --url "$CODER_URL"
./setup_study_participants.sh 10
```

The script writes generated participant credentials under
`participant_credentials/`. That directory is intentionally ignored by Git.

## 7. Create Workspaces

Participants can create their own workspaces after logging in to Coder, or an
administrator can create workspaces for them.

Example participant-created workspace:

```bash
coder create participant1/participant1-ctf --template ctf-p
```

Example administrator-created workspace:

```bash
coder workspaces create \
  --template ctf-p \
  --name participant1-ctf \
  --owner participant1
```

Verify workspace status:

```bash
coder workspaces list
```

## 8. Optional Log Management Stack

The log-management files under `infrastructure/log-management/` provide an
optional Loki, Promtail, and Grafana stack. This stack is included as deployment
reference material and may need adjustment for a new deployment.

Before starting it, set a Grafana password:

```bash
export GRAFANA_ADMIN_PASSWORD="replace-with-a-strong-password"
cd infrastructure/log-management
docker compose up -d
```

Grafana is exposed locally on port `8000` by default.

## 9. Verification Checklist

Use this short checklist before running a study:

- `docker pull <ctf-p-image>` succeeds on the Coder VM
- `coder templates list` shows the `ctf-p` template
- a test participant user can log in to Coder
- a test workspace starts successfully
- the workspace opens a terminal as the intended participant user
- `supervisorctl status` inside the workspace shows challenge services running
- the Flask app is reachable on port `8000` inside the challenge environment
- SSH access works for local Docker testing with `jdoe`

## Troubleshooting

Useful commands on the Coder VM:

```bash
docker ps
docker images
docker logs <workspace-container-name> --tail 100
coder templates list
coder workspaces list
coder users list
```

If workspace creation fails, first check that the VM can pull the configured
CTF-P image and that the Docker daemon is running.
