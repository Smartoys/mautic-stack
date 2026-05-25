# Synology backup setup

Step-by-step walkthrough to wire a new SFTP backup destination on the
Synology NAS (`servone.kemushi.eu:2222`) and prove key auth works from
the Mautic host before letting the container take over.

The container side (Dockerfile, scripts, compose) is documented by the
files in this directory. This README is about the one-time **Synology
side + SSH key plumbing** — the part you can't script away.

If you're adding a *second* backup that pushes to the same `backup_mautic`
user, you can skip this whole guide — just point a new container at the
existing key.

## 0. Prerequisites

- DSM admin account on the Synology
- SSH access to the Mautic host as a sudo-capable user (e.g. `dsonnet@192.168.81.67`)
- Decide a name for the dedicated NAS user (e.g. `backup_<purpose>`)
- Decide the target path on the NAS (e.g. `/Mautic/backup/database`)

## 1. Create the dedicated NAS user

In DSM web UI:

1. **Control Panel → User & Group → Create**
2. Name: `backup_<purpose>` (e.g. `backup_mautic`)
3. Set a strong password. Key auth will be used, but DSM requires a password to exist.
4. **Joined groups** tab → leave on `users` only (no admin)
5. **Applications** tab → uncheck everything *except* `SFTP`. This user can ONLY do SFTP.
6. (Optional) **Quota** tab → cap disk usage based on retention needs.
7. Finish.

## 2. Create the shared folder

1. **Control Panel → Shared Folder → Create** → name (e.g. `Mautic`)
2. Pick the volume that holds your other backups.
3. **Permissions** tab → grant `backup_<purpose>` **Read/Write**, deny everyone else.
4. After creation: in **File Station**, browse into the share and create the
   subfolder structure you want (e.g. `Mautic/backup/database/`). Pre-create
   it so the container doesn't have to.

## 3. Enable SFTP and user home service

Both required. Both easy to forget — and they fail *silently*.

1. **Control Panel → File Services → FTP → SFTP tab** → check **Enable SFTP service**.
   Confirm the port (we use `2222`).
2. **Control Panel → User & Group → Advanced** → scroll down → check
   **Enable user home service**. Without this, `~backup_<purpose>/.ssh/authorized_keys`
   has no `~` to live in and key auth quietly falls back to password.

## 4. Generate an SSH key on the Mautic host

The key lives on the host and gets bind-mounted into backup containers.
Generate it once, share across all backup containers that use the same NAS user.

```bash
ssh dsonnet@192.168.81.67
sudo mkdir -p /portainer/db-backup
sudo ssh-keygen -t ed25519 \
  -f /portainer/db-backup/id_ed25519 \
  -C "mautic-db-backup@$(hostname)" \
  -N ""
sudo chmod 600 /portainer/db-backup/id_ed25519
sudo chmod 644 /portainer/db-backup/id_ed25519.pub
sudo cat /portainer/db-backup/id_ed25519.pub
```

Copy the printed `ssh-ed25519 AAAA…` line.

## 5. Install the pubkey on the NAS

The backup user has no shell access (we disabled all apps except SFTP),
so `ssh-copy-id` won't work. Install manually as a DSM admin:

```bash
ssh -p 2222 <admin_user>@servone.kemushi.eu
sudo -i
HOME_DIR=/var/services/homes/backup_<purpose>
mkdir -p $HOME_DIR/.ssh
echo 'ssh-ed25519 AAAA…paste your pubkey here…' > $HOME_DIR/.ssh/authorized_keys
chown -R backup_<purpose>:users $HOME_DIR/.ssh
chmod 700 $HOME_DIR/.ssh
chmod 600 $HOME_DIR/.ssh/authorized_keys
chmod 700 $HOME_DIR
exit; exit
```

**Permissions matter.** sshd refuses keys if any of these are wrong:
- home dir: `700` (or at minimum not group-writable)
- `~/.ssh`: `700`
- `~/.ssh/authorized_keys`: `600`
- Owner of all three: the backup user, not root.

## 6. Gating test — does key auth work?

From the Mautic host:

```bash
sudo sftp -i /portainer/db-backup/id_ed25519 \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  -o UserKnownHostsFile=/portainer/db-backup/known_hosts \
  -P 2222 \
  backup_<purpose>@servone.kemushi.eu
```

At the `sftp>` prompt:

```
sftp> pwd
sftp> ls -la
sftp> cd Mautic/backup/database
sftp> put /etc/hostname
sftp> ls
sftp> rm hostname
sftp> bye
```

What you should see:
- **No password prompt.** `BatchMode=yes` would abort with a clear error if password fallback were needed.
- `pwd` returns a chroot path (e.g. `/`, not `/var/services/homes/...`). That tells you what `REMOTE_PATH` looks like from the container's perspective.
- `cd` into your target subfolder succeeds.
- `put`/`rm` succeed.

If any of that fails, fix the Synology side before continuing — the
container can't fix permission/auth bugs.

## 7. Wire it into a backup container

You now have everything the container needs:

| What | Where |
|---|---|
| Private key | `/portainer/db-backup/id_ed25519` (bind-mount into container) |
| SSH host/port/user | `servone.kemushi.eu` / `2222` / `backup_<purpose>` |
| Remote path | what `pwd` showed in step 6, plus your subdir |

See `docker-compose.percona.yml` in the parent directory for the
`db-backup-smartoys` / `db-backup-dlgamer` services — copy that pattern
for any new backup.

The container will do mysqldump → gzip → sftp using the same system
tools you just tested manually, with the same key. If step 6 worked,
the container will too.

## Adding to a different stack

The pattern generalises beyond MySQL. To back up something else (a
docker volume, a file dir, an app export):

1. Same Synology user / key (no need to provision again — one user can serve many backup containers).
2. Replace `mariadb-dump | gzip` in `backup.sh` with whatever produces your dump.
3. Adjust `REMOTE_PATH` to a different subdir on the NAS.
4. Pick a non-overlapping cron slot.

## Operational notes

- **Schedule:** weekly on Sunday. Smartoys 03:00 UTC, dlgamer 04:00 UTC. Smartoys runtime observed ~22 min.
- **Verify recent backups:**
  ```bash
  ssh dsonnet@192.168.81.67 'sudo bash -c "echo -e \"cd /Mautic/backup/database\nls -l\" | sftp -i /portainer/db-backup/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P 2222 -b - backup_mautic@servone.kemushi.eu"'
  ```
- **Force a one-shot backup** (e.g. before a risky migration):
  ```bash
  ssh dsonnet@192.168.81.67 'sudo docker exec db-backup-smartoys /usr/local/bin/backup.sh'
  ```
- **Rotate the SSH key:** regenerate (step 4), install (step 5), test (step 6). Both
  containers pick up the new key on next restart since they bind-mount the same file path.
- **Rotate a DB password:** update in MySQL (`ALTER USER ... IDENTIFIED BY ...`),
  update `DB_BACKUP_<SVC>_PASSWORD` in Portainer's percona stack env vars, redeploy.
