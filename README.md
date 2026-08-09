# XNS Relayer — Quickstart

Run a self-hosted [XNS Relayer](https://xns.tech) from a single `docker compose up`.
The Relayer is an S3-compatible distributed storage gateway — it exposes a standard
S3 API on port 9000 and a web dashboard on port 8888.

> **Pre-release.** This quickstart pulls from the public beta channel. Images are
> updated regularly; run `docker compose pull && docker compose up -d` to get the
> latest build.

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Docker Engine (or Docker Desktop) | 20.10+ with the Compose V2 plugin |
| Memory | 4 GB (8 GB recommended) |
| Free disk | 10 GB |
| Free ports | 8888, 9000, 9443 |

You will also need an **xns account** (free to create) to claim the Relayer in
step 4, and a device with a browser you can sign in on.

## Quick start

### 1. Get the compose file

```bash
git clone https://github.com/xns-cloud/relayer-quickstart.git
cd relayer-quickstart
```

If you would rather not clone, create an empty directory and copy
[`docker-compose.yml`](docker-compose.yml) into it — that file is all you need.

### 2. Optional: change the ports

If 8888, 9000, or 9443 are already in use, copy
[`.env.example`](.env.example) to `.env` and uncomment the port lines:

```bash
cp .env.example .env
# edit .env — uncomment and change any port that conflicts
```

### 3. Start the Relayer

```bash
docker compose up -d
```

The first run downloads the image (a few hundred MB). When it finishes, open
**<http://localhost:8888>** in your browser.

### 4. Claim your Relayer

Claiming connects this Relayer to your xns account. Until it is claimed, the
Relayer runs but has no owner and storage operations do not persist to the
network.

1. Open **<http://localhost:8888>**. A **"Welcome to your Relayer"** dialog
   appears with two choices: **Connect to xns** and **I already have an
   account**.
2. Click **Connect to xns**. The dialog switches to a panel headed *"Complete
   this on another device"* and displays a **claim link** plus an expiry time.
3. **Open that link in a browser where you can sign into your xns account** —
   the same machine is fine, or copy the link to your phone or laptop. Use the
   **Copy link** button. Sign in (or create an account) and approve the claim
   there.
4. Return to the dashboard. It detects the completed claim on its own and
   refreshes — **within 15 minutes**, usually within a minute. You do not need
   to restart the container or reload manually.

Once the claim completes, the dashboard leaves the welcome dialog and shows the
normal owned view. You are the box owner.

> **What just happened?** The claim link ties this Relayer to your xns identity.
> The dashboard writes the resulting credential into the container so the
> storage engine can use it as its identity on every subsequent start. There is
> no file to edit by hand.

### 5. Verify

| Check | Expected |
|-------|----------|
| Dashboard loads at `http://localhost:8888` | The owned dashboard — not the "Welcome to your Relayer" dialog |
| Container is healthy | `docker compose ps` shows `xns-relayer` as `Up` |
| S3 port is bound | `docker compose ps` lists `0.0.0.0:9000->9000/tcp` |

Then point any S3-compatible client at `http://localhost:9000` to start storing
objects. Generate the access key and secret key your client needs from the
**IAM** section of the dashboard.

> The S3 gateway only starts serving once the Relayer is claimed. Before that,
> port 9000 accepts connections but returns nothing — that is expected, not a
> fault.

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8888 | HTTP | Web dashboard |
| 9000 | HTTP | S3 API |
| 9443 | HTTPS | S3 API (active once a TLS certificate is installed) |

All three are configurable through the `.env` file.

> **Exposure.** The compose file publishes these ports on every host interface.
> That is fine on a laptop or a machine behind a firewall. On a cloud VM with a
> public IP, restrict them — a firewall rule, or bind to loopback in the compose
> file (`"127.0.0.1:8888:8888"`) — at least until the Relayer is claimed. Before
> claiming, anyone who can reach port 8888 sees the claim dialog.

## Storage and disks

This quickstart runs the container **unprivileged**, which is the right default
for a public, single-command install. Storage lives in a Docker-managed named
volume (`relayer_data`) and grows into the space available on the Docker host —
enough to install, claim, and use the S3 API.

Some features need access the container does not have by default:

| Feature | Needs |
|---------|-------|
| Attaching and formatting physical disks from the dashboard | `privileged: true` |
| Cloud Sync (rclone/FUSE mounts) | `/dev/fuse` and `CAP_SYS_ADMIN` |
| SMB / Windows file shares | additional published ports and capabilities |

If you need those, add the access explicitly to the `relayer` service in
`docker-compose.yml` — for example:

```yaml
    privileged: true
```

and run `docker compose up -d` again. Understand what that grants before you do
it: a privileged container has effectively root-level access to the host.

If you skip it, nothing crashes. The disk-management pages simply have no
physical disks to offer, and the sync and share features stay unavailable —
everything else in the walkthrough above works normally.

## Updating

```bash
docker compose pull
docker compose up -d
```

Your data lives in the `relayer_data` volume and survives image updates.

`beta-latest` is a moving tag — each `pull` fetches the newest beta build. For a
deployment you want to hold steady, replace the tag in `docker-compose.yml` with
a specific version and change `pull_policy: always` to `pull_policy: missing`.

## Stopping and removing

```bash
# Stop, keep data
docker compose down

# Stop and delete all data (irreversible)
docker compose down -v
```

## Troubleshooting

**"port is already allocated"** — Another process is using 8888, 9000, or
9443. Copy `.env.example` to `.env`, uncomment the port lines, and pick free
port numbers.

**"unauthorized" on image pull** — The beta channel is public (no login
needed). If you see this, a stale registry login may be cached — run
`docker logout releases.scpri.me` and retry.

**The claim link expired** — Click **Back**, then **Connect to xns** again to
mint a fresh link.

**The dashboard still shows the welcome dialog after claiming** — Give it up to
15 minutes; it polls on its own. If it has not changed by then, reload the page.

**Container won't start or keeps restarting** — Check the logs:

```bash
docker compose logs --tail=100
```

**Can't reach the dashboard** — Confirm you are using `http://` (not
`https://`) and that `docker compose ps` shows the container as `running`.

## Using an AI assistant

The [relayer-mcp](https://github.com/xns-cloud/relayer-mcp) package lets
Claude (or any MCP-capable assistant) install and manage the Relayer for you.
Add it to your assistant and ask it to install the XNS Relayer — it handles
the setup, account creation, and verification.

## Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) — please report it
privately.

## License

[Apache-2.0](LICENSE)
