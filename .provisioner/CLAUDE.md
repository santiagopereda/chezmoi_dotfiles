# Workstation Provisioner

## Location

The provisioner lives inside the chezmoi dotfiles repo at `~/.local/share/chezmoi/.provisioner/`. The repo at `~/Documents/workstation-provisioner/` is a stale copy — always work in the chezmoi path.

The chezmoi dotfiles repo is at `https://github.com/santiagopereda/chezmoi_dotfiles.git`.

## How It Runs

Chezmoi triggers Ansible via `run_onchange_after_ansible-provision.sh.tmpl`. That script hashes key files — when any hash changes, chezmoi re-runs the playbook automatically. The bootstrap script (`run_once_before_01-install-ansible.sh.tmpl`) installs Ansible via pipx on first `chezmoi init`.

**Important:** The bootstrap script does NOT install chezmoi itself. On a fresh machine, install chezmoi first, then it bootstraps everything else.

## Bootstrapping a New Machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply santiagopereda/chezmoi_dotfiles
```

Do NOT use `snap install chezmoi` — the sandbox prevents dotfile management.

**Common issue:** On first boot, unattended apt upgrades may hold the dpkg lock. Wait for it:
```bash
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo "waiting..."; sleep 5; done
```
Then re-run: `chezmoi init --apply santiagopereda/chezmoi_dotfiles`

After init, create per-machine overrides:
```bash
cp ~/.local/share/chezmoi/.provisioner/host_vars/example.yml.dist \
   ~/.local/share/chezmoi/.provisioner/host_vars/localhost.yml
```

## Updating a Provisioned Machine

SSH into the machine and run:
```bash
chezmoi update
```

If chezmoi isn't in PATH (e.g., fresh Pi), install it first:
```bash
sh -c 'curl -fsLS get.chezmoi.io | sh -s -- -b ~/.local/bin'
~/.local/bin/chezmoi update
```

## Structure

```
.provisioner/
  ansible.cfg           # Points to local inventory (no global become)
  local.yml             # Main playbook
  inventory/localhost    # Single-host inventory
  group_vars/all.yml    # Shared defaults
  host_vars/
    example.yml.dist    # Template — copy to localhost.yml per machine
  roles/
    common/             # Base packages (apt/brew)
    security/           # SSH hardening, fail2ban, ufw firewall
    docker/             # Docker CE install
    shell/              # Zsh, oh-my-zsh
    python/             # Python versions via uv
    fonts/              # Nerd Fonts
```

## Role Execution Order (local.yml)

common → security → docker → shell → python → fonts

## Privilege Escalation

Global `become: true` was removed from `ansible.cfg`. Each task that needs root has `become: true` set individually. This prevents `ansible_user_id` (and `desktop_user`) from resolving to `root` — which previously caused SSH AllowUsers to deploy `root`, shell/fonts/docker to target root's home, etc.

When running manually, pass `-K` for the sudo password prompt:
```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook local.yml --check --diff -K
```

## Security Role

Hardens SSH with a drop-in config (`/etc/ssh/sshd_config.d/99-hardening.conf`) and configures fail2ban with ignoreip whitelist. Key design:

- **sshd -t validation** before restart (handler chain with `listen`) prevents lockout
- **Drop-in file** — doesn't touch base sshd_config, easy to remove
- **Include directive check** — fails clearly on systems without OpenSSH 8.2+
- **ignoreip** — whitelist trusted networks to prevent self-banning (set per-host in `host_vars/localhost.yml`)
- Variables use `security_ssh_` prefix (SSH) and `security_fail2ban_` prefix (fail2ban)
- fail2ban ignoreip is static — add your LAN subnet manually in `host_vars/localhost.yml`

## host_vars/localhost.yml

Per-machine overrides. Not committed to the repo. Copy from `example.yml.dist`. This is where LAN subnets go for fail2ban ignoreip. Example for Pi on home network:

```yaml
security_fail2ban_ignoreip:
  - 127.0.0.1/8
  - "::1"
  - 192.168.9.0/24
```

## Supported Platforms

Debian/Ubuntu and macOS. The security role's fail2ban and firewall tasks are Linux-only (`when: ansible_os_family == "Debian"`). SSH hardening supports both via separate tasks.

## Target Machines

- Local workstation (Ubuntu)
- Raspberry Pi 5 at `192.168.9.192` (Ubuntu, user `askeox`, SSH key `~/.ssh/askeox_particle`)

## Dotfiles (chezmoi-managed, outside .provisioner/)

### .zshenv (`dot_zshenv.tmpl`)
- Sets XDG base directories and ZDOTDIR
- XDG overrides for tools (aws, docker, gnupg, jupyter, pip)
- PATH additions (`~/.local/bin`, Go, Cargo) — all guarded
- WSL browser export (conditional via chezmoi template)
- **No heavy loading here** — nvm was moved to `.zshrc` to avoid slowing non-interactive shells

### .zshrc (`private_dot_config/zsh/dot_zshrc`)
- p10k instant prompt at top
- oh-my-zsh with plugins: git, sudo, web-search, copypath, copyfile, copybuffer, dirhistory, history, jsontools, zsh-autosuggestions, F-Sy-H
- F-Sy-H replaces zsh-syntax-highlighting (do NOT add both)
- History: 10000 entries, set only in `.zshrc` (not `.zshenv`)
- `setopt CORRECT` (commands only, NOT `CORRECT_ALL`)
- Completion dump location set via `ZSH_COMPDUMP` (do NOT call `compinit` manually — oh-my-zsh handles it)
- direnv, nvm, pyenv all guarded with `command -v` checks
- Aliases live in `.chezmoifiles/aliases.zsh`, deployed via `run_onchange_after_copy-omz-custom.sh.tmpl` to `~/.config/oh-my-zsh/custom/`

### tmux (`private_dot_config/tmux/`)
- Prefix: `C-Space`
- Navigation: hjkl panes, Shift-arrows windows, `|` and `-` splits
- Resizing: `H/J/K/L` (repeatable)
- Vi copy mode (`v` select, `y` yank)
- `escape-time 10` and `focus-events on` for neovim
- `tmux-256color` with RGB true color override
- Status bar scripts (`is_online.sh`, `remote_online.sh`, `battery_meter.sh`) have known issues — they use temp files without locking and `battery_meter.sh` fails on machines without batteries

### Known Gotchas
- `aliases.zsh` must end with a newline, otherwise the heredoc in `copy-omz-custom.sh.tmpl` breaks
- `chezmoi apply` on local machine will overwrite any manual additions to `.zshrc` (e.g., lines added by pipx or cargo). Add those to the template instead.
- `.chezmoiignore` excludes `.provisioner/` from chezmoi target — Ansible files stay in source only
