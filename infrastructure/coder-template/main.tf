terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  username              = data.coder_workspace_owner.me.name
  session_log_host_path = "/var/lib/ctf-p/session-logs/${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.id}"
}

variable "docker_socket" {
  default     = ""
  description = "(Optional) Docker socket URI"
  type        = string
}

provider "docker" {
  # Defaulting to null if the variable is an empty string lets us have an optional variable without having to set our own default
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi

  EOT

    display_apps {
    vscode                 = false
    vscode_insiders        = false
    ssh_helper             = false
    port_forwarding_helper = false
    web_terminal           = true
  }
}


resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

# CTF Data volume for persistent logging and terminal recordings
# NOTE: Volume-based storage disabled due to permission issues in cloud environments
# Using Docker API-based streaming instead for better cloud compatibility
# resource "docker_volume" "ctf_data_volume" {
#   name = "coder-${data.coder_workspace.me.id}-ctf-data"
#   # Protect the volume from being deleted due to changes in attributes.
#   lifecycle {
#     ignore_changes = all
#   }
#   # Add labels in Docker to keep track of orphan resources.
#   labels {
#     label = "coder.owner"
#     value = data.coder_workspace_owner.me.name
#   }
#   labels {
#     label = "coder.owner_id"
#     value = data.coder_workspace_owner.me.id
#   }
#   labels {
#     label = "coder.workspace_id"
#     value = data.coder_workspace.me.id
#   }
#   labels {
#     label = "coder.workspace_name_at_creation"
#     value = data.coder_workspace.me.name
#   }
#   labels {
#     label = "coder.data_type"
#     value = "ctf-research-data"
#   }
# }



resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "ghcr.io/example-org/ctf-p:latest"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name


  entrypoint = ["sh", "-c", "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf & sleep 3 && export CODER_AGENT_TOKEN='${coder_agent.main.token}' && su jdoe -c '${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}'"]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}"
  ]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  # Mount home directory for user data persistence
  volumes {
    volume_name    = docker_volume.home_volume.name
    container_path = "/home/jdoe"
  }

  # Persist session logs on the VM so research data survives workspace stops.
  # The workspace container is destroyed when stop_count goes to 0, so relying
  # only on Docker's json-file logs loses data as soon as the container is
  # removed.
  volumes {
    host_path      = local.session_log_host_path
    container_path = "/var/log/sessions"
  }


  # External logging via Docker logs - no volume mount needed
  # Logs are captured by Docker logging driver and streamed externally

  # Configure Docker logging for enhanced CTF session capture
  # This configuration integrates with the enhanced logging system in log-management/
  # All labels defined below are extracted by Promtail for sophisticated filtering in Grafana
  log_driver = "json-file"
  log_opts = {
    "max-size" = "100m"
    "max-file" = "10"
    "labels"   = "participant_id,workspace_id,log_type"
    "tag"      = "ctf-workspace-{{.Name}}"
  }

  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }

  # Essential labels for basic filtering
  labels {
    label = "participant_id"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "log_type"
    value = "ctf-activity"
  }
}
