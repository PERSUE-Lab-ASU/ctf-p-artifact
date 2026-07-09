# Studying Personality and Attacker Behavior in a Deceptive Multi-Stage Capture-the-Flag Environment

This repository contains the public artifact for CTF-P, a containerized cybersecurity task environment used to study participant behavior in a deceptive, multi-stage capture-the-flag environment.

The CTF-P environment presents participants with a realistic Linux-based corporate setting containing multiple security tasks, decoy paths, runtime-generated secrets, and researcher-facing instrumentation. It was designed to support research on attacker behavior, decision-making, persistence, risk-taking, and related personality-linked patterns during security problem solving.

## Acknowledgement
This project is supported by the Air Force Office of Scientific Research (AFOSR) (Award #FA9550-24-1-0227). Any opinions, findings, and conclusions or recommendations expressed in this paper are those of the author(s) and do not necessarily reflect the views of the Air Force Office of Scientific Research (AFOSR).

## Artifact Scope

The artifact focuses on the reproducible system components:

- challenge image build files
- task setup and runtime configuration scripts
- participant workspace configuration for Coder
- GCP/Coder deployment notes
- logging and observability configuration

Private analysis workspaces, paper drafts, raw participant data, exports, and internal notes are intentionally not included.

## Repository Layout

```text
.
├── Dockerfile
├── docker-compose.yml
├── supervisord.conf
├── tasks/
│   ├── CTF_DOCUMENTATION.md
│   ├── app.py
│   ├── setup.sh
│   ├── start.sh
│   ├── logging.sh
│   ├── randomize_system.sh
│   ├── stealth_runtime_export.sh
│   └── task_*.sh
├── infrastructure/
│   ├── coder-gcp-deployment.md
│   ├── coder-template/main.tf
│   ├── participant-setup/
│   └── log-management/
```

## Local Build and Run

Requirements:

- Docker
- Docker Compose

Build and start the local challenge container:

```bash
docker compose up --build -d
```

Connect to the challenge container over SSH:

```bash
ssh jdoe@localhost -p 2222
```

Default entry credentials for local testing:

```text
username: jdoe
password: welcome123
```

Stop the local container:

```bash
docker compose down
```

## Challenge Environment

The challenge image is built from the top-level `Dockerfile`. During image build, `tasks/setup.sh` runs the task setup scripts and prepares the simulated corporate Linux environment.

At container startup, `supervisord.conf` starts the challenge services, including SSH, cron, the vulnerable Flask application, runtime setup, and logging helpers.

The main task implementation lives in `tasks/`:

- `task_global.sh`: base users, groups, and corporate filesystem structure
- `task_a1.sh`: password cracking task setup
- `task_a.sh`: SQL injection task setup
- `task_b1.sh`: cron-based task setup
- `task_b2.sh`: SUID binary task setup
- `task_b3.sh`: buffer-overflow task setup
- `stealth_runtime_export.sh`: per-container runtime passwords, flags, and setup export
- `logging.sh`: shell, process, and file activity logging

For more detail, see `tasks/CTF_DOCUMENTATION.md`.

## Deployment on GCP with Coder

The participant deployment model uses open source Coder on a GCP VM. Each participant receives a Coder workspace backed by a Docker container built from the CTF-P image.

Relevant files:

- `infrastructure/coder-gcp-deployment.md`: GCP/Coder deployment guide
- `infrastructure/coder-template/main.tf`: Coder workspace template
- `infrastructure/participant-setup/`: helper scripts for creating Coder users
- `infrastructure/log-management/`: Loki, Promtail, and Grafana configuration

The Coder template uses a placeholder challenge image:

```hcl
image = "ghcr.io/example-org/ctf-p:latest"
```

Before deploying the Coder template, replace this with the Docker image you build and publish for your own artifact deployment.

## Logging and Data Collection

The artifact includes the logging configuration used to capture participant activity from challenge containers. The public repository includes only configuration files and dashboards. It does not include raw logs, participant exports, analysis outputs, or personally identifying participant data.

Session logs are written inside the container under:

```text
/var/log/sessions
```

The Coder deployment maps this path to a persistent host directory so data can survive workspace stops and container removal.

## Related Publications

This artifact is associated with the following research papers:

- **Profiling Human Attackers: Personality and Behavioral Patterns in Deceptive Multi-Stage CTF Challenges**. 
Vision paper, published at USEC-NDSS 2026. 
https://www.ndss-symposium.org/ndss-paper/vision-profiling-human-attackers-personality-and-behavioral-patterns-in-deceptive-multi-stage-ctf-challenges/

- **Studying Personality and Attacker Behavior in a Deceptive Multi-Stage Capture-the-Flag Environment**. 
Accepted at the Conference on Sociotechnical Cybersecurity and Privacy (SCP2026). 
Public citation details will be added when the official paper page is available. 
https://scpconf.eu/

Please cite the relevant paper when using or adapting this artifact.

## Contact

Khalid Alasiri  
School of Computing and Augmented Intelligence  
Arizona State University  
kl1d@asu.edu

## Acknowledgment

This research was supported by the Air Force Office of Scientific Research (AFOSR) under Award FA9550-24-1-0227. Any opinions, findings, conclusions, or recommendations expressed in this paper are those of the author(s) and do not necessarily reflect the views of AFOSR.

## License

This artifact is released under the MIT License. See `LICENSE`.
