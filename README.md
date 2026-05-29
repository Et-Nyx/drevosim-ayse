# Taluji

NixOS configuration flake for `portaible` (and future hosts).

---

## TODO: Set Up agenix Secrets on Portaible

After booting into `portaible` and pulling this branch:

### 1. Get the host's SSH public key
```bash
cat /etc/ssh/ssh_host_ed25519_key.pub
```

### 2. Update `siri/secrets.nix`
- [ ] Replace the placeholder `portaible` key with the real host public key from step 1
- [ ] Replace the placeholder `admin` key with your personal SSH public key (e.g. `~/.ssh/id_ed25519.pub` or `~/.ssh/gitlab/gitlab_ed25519.pub`)

### 3. Delete the dummy `.age` placeholders
```bash
rm siri/*.age
```

### 4. Encrypt the secrets
From inside the `siri/` directory:
```bash
cd siri
nix run github:ryantm/agenix -- -e portaible-root-password.age
nix run github:ryantm/agenix -- -e portaible-eter-password.age
```
Each command opens your editor — paste the sha-512 hashed password (generate one with `mkpasswd -m sha-512` if needed), save, and quit.

### 5. Rebuild the system
```bash
sudo nixos-rebuild switch --flake .#portaible
```

### 6. Commit and push
- [ ] Commit the encrypted `.age` files and updated `secrets.nix`
- [ ] Push to GitLab
