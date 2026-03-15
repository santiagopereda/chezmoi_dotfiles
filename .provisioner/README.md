# Workstation Provisioner

Ansible-based workstation provisioner embedded in a [chezmoi](https://www.chezmoi.io/) dotfiles repo. Automatically provisions development tools, hardens SSH, and configures services on Debian/Ubuntu and macOS.

## How It Works

This provisioner lives at `.provisioner/` inside the chezmoi source directory. Chezmoi runs it automatically:

1. **First run** (`chezmoi init`): Installs Ansible via `run_once_before_01-install-ansible.sh.tmpl`
2. **Subsequent runs** (`chezmoi apply`): Re-runs the playbook when tracked files change, detected via sha256 hashes in `run_onchange_after_ansible-provision.sh.tmpl`

## Bootstrapping a New Machine

### Quick start (all defaults)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply santiagopereda/chezmoi_dotfiles
```

> The `-b ~/.local/bin` flag is **required** — without it, the chezmoi binary is installed to a temp directory and lost after the init.

### With per-machine config (recommended)

Use `--no-scripts` to initialize chezmoi without running the provisioner, set up your `host_vars/localhost.yml` first, then apply:

```bash
# 1. Install chezmoi and clone dotfiles (no scripts run yet)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply --no-scripts santiagopereda/chezmoi_dotfiles

# 2. Create per-machine overrides
cp ~/.local/share/chezmoi/.provisioner/host_vars/example.yml.dist \
   ~/.local/share/chezmoi/.provisioner/host_vars/localhost.yml

# 3. Edit localhost.yml for this machine (see "Per-machine overrides" below)
nano ~/.local/share/chezmoi/.provisioner/host_vars/localhost.yml

# 4. Run the full apply (triggers Ansible provisioner)
~/.local/bin/chezmoi apply
```

> **Note:** Do not use `snap install chezmoi` — the sandbox prevents dotfile management.

## Roles

| Role | Description | Platforms |
|------|-------------|-----------|
| **common** | Base packages (git, neovim, tmux, ripgrep, etc.) and CLI tools (lazydocker, lazygit, yq, delta, tealdeer) | Debian, macOS |
| **security** | SSH hardening, fail2ban, ufw firewall | SSH: both; fail2ban/ufw: Debian only |
| **docker** | Docker CE installation and user group config | Debian |
| **shell** | Zsh and oh-my-zsh with plugins | Debian, macOS |
| **python** | Python versions via uv | Debian, macOS |
| **node** | Node.js versions via fnm | Debian, macOS |
| **apps** | Desktop applications (browsers, editors, tools), external apt repos, snap packages, terminal emulators | Debian, macOS |
| **fonts** | Nerd Fonts (Hack) | Debian, macOS |

Roles run in this order: common → security → docker → shell → python → node → apps → fonts

The `apps` role only runs when `desktop_mode: true` (the default).

## Configuration

### Global defaults

Edit `group_vars/all.yml` for shared settings across all machines.

### Per-machine overrides

Create `host_vars/localhost.yml` from the provided example:

```bash
cp host_vars/example.yml.dist host_vars/localhost.yml
```

This file is **gitignored** and never committed. Use it to customize settings per machine.

#### Key variables

```yaml
---
# Headless/server mode — set to false to skip the apps role entirely
desktop_mode: false

# Terminal emulators (both default to false)
install_kitty: true
install_ghostty: true

# Python versions
python_versions:
  - "3.13"
  - "3.12"

# Node.js versions
node_versions:
  - "22"
  - "20"

# Extra packages (appended to the defaults, not replacing)
extra_packages_debian:
  - htop
  - strace

# SSH / fail2ban tuning
security_ssh_max_auth_tries: 3
security_fail2ban_maxretry: 3
security_fail2ban_ignoreip:
  - 127.0.0.1/8
  - "::1"
  - 192.168.1.0/24   # your LAN subnet
```

### Security role

The security role deploys a drop-in SSH config at `/etc/ssh/sshd_config.d/99-hardening.conf` and configures fail2ban with a trusted network whitelist.

Safety features:

- **sshd -t validation** runs before any sshd restart — bad configs won't lock you out
- **Drop-in config** (`99-hardening.conf`) — easy to remove manually without touching the base sshd_config
- **Include directive check** — fails with a clear message on systems without OpenSSH 8.2+

Set `security_fail2ban_ignoreip` in `host_vars/localhost.yml` to whitelist your LAN and prevent self-banning when SSH agent offers multiple keys.

### Terminal emulators

Kitty and Ghostty are opt-in via `host_vars/localhost.yml`:

| Variable | Default | Debian | macOS |
|---|---|---|---|
| `install_kitty` | `false` | apt package | Homebrew cask |
| `install_ghostty` | `false` | PPA (`ppa:ghostty/release`) | Homebrew cask |

### Architecture handling

Some packages are amd64-only (Brave, 1Password, Spotify, Bitwarden, DBeaver CE, Drawio). These are automatically skipped on arm64 (e.g., Raspberry Pi).

## Manual Usage

```bash
# Dry run
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --check --diff

# Run a specific role
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --tags security

# Run only terminal emulators
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --tags terminals

# Full provision
ANSIBLE_CONFIG=.provisioner/ansible.cfg ansible-playbook .provisioner/local.yml --diff
```
