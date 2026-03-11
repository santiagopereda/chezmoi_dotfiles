# Workstation Provisioner

Ansible-based workstation provisioner embedded in a [chezmoi](https://www.chezmoi.io/) dotfiles repo. Automatically provisions development tools, hardens SSH, and configures services on Debian/Ubuntu and macOS.

## How It Works

This provisioner lives at `.provisioner/` inside the chezmoi source directory. Chezmoi runs it automatically:

1. **First run** (`chezmoi init`): Installs Ansible via `run_once_before_01-install-ansible.sh.tmpl`
2. **Subsequent runs** (`chezmoi apply`): Re-runs the playbook when tracked files change, detected via sha256 hashes in `run_onchange_after_ansible-provision.sh.tmpl`

## Bootstrapping a New Machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
export PATH="$HOME/bin:$PATH"
chezmoi init --apply https://github.com/santiagopereda/chezmoi_dotfiles.git
```

> **Note:** Do not use `snap install chezmoi` — the sandbox prevents dotfile management.

After the initial run, create per-machine overrides:

```bash
cp ~/.local/share/chezmoi/.provisioner/host_vars/example.yml.dist \
   ~/.local/share/chezmoi/.provisioner/host_vars/localhost.yml
```

## Roles

| Role | Description | Platforms |
|------|-------------|-----------|
| **common** | Base packages (git, neovim, tmux, etc.) | Debian, macOS |
| **security** | SSH hardening, fail2ban, ufw firewall | SSH: both; fail2ban/ufw: Debian only |
| **docker** | Docker CE installation | Debian |
| **shell** | Zsh and oh-my-zsh | Debian, macOS |
| **python** | Python versions via uv | Debian, macOS |
| **fonts** | Nerd Fonts | Debian, macOS |

Roles run in this order: common → security → docker → shell → python → fonts

## Configuration

### Global defaults

Edit `group_vars/all.yml` for shared settings across all machines.

### Per-machine overrides

Edit `host_vars/localhost.yml` with machine-specific values. This file is not committed to the repo.

### Security role

The security role deploys a drop-in SSH config at `/etc/ssh/sshd_config.d/99-hardening.conf` and configures fail2ban with a trusted network whitelist.

Key variables:

```yaml
# SSH
security_ssh_port: 22
security_ssh_max_auth_tries: 6
security_ssh_permit_root_login: "no"
security_ssh_password_authentication: "no"
security_ssh_allowed_users: "{{ desktop_user }}"

# fail2ban
security_fail2ban_maxretry: 5
security_fail2ban_ignoreip:
  - 127.0.0.1/8
  - "::1"
  - 192.168.1.0/24  # add your LAN subnet
```

Set `security_fail2ban_ignoreip` in `host_vars/localhost.yml` to whitelist your LAN and prevent self-banning when SSH agent offers multiple keys.

### Safety features

- **sshd -t validation** runs before any sshd restart — bad configs won't lock you out
- **Drop-in config** (`99-hardening.conf`) — easy to remove manually without touching the base sshd_config
- **Include directive check** — fails with a clear message on systems without OpenSSH 8.2+

## Manual Usage

```bash
# Dry run
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --check --diff

# Run a specific role
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --tags security

# Full provision
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --diff
```
