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

## Quick start

### 1. Create a project directory

```bash
mkdir -p ~/xns-relayer
cd ~/xns-relayer
```

### 2. Save the compose file

Download or copy
[`docker-compose.yml`](docker-compose.yml)
into `~/xns-relayer`.

If you need to change the default ports (8888 / 9000 / 9443), copy
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

On first launch the dashboard presents the **onboarding wizard**. This is the
step that makes the Relayer yours — it writes the identity credential the
storage engine needs to operate.

1. Open **<http://localhost:8888>**.
2. The wizard prompts you to **sign in or create an XNS account** (email
   verification required).
3. After signing in, the wizard mints a credential and writes it into the
   container at `/relayer/conf/hostioauth`. This happens automatically — no
   manual file editing.
4. Once the credential is written, the dashboard transitions to the
   **claimed / owned** state. You are now the box owner.

> **What just happened?** The onboarding wizard contacted XNS's identity
> service, obtained a Muse access token for your account, and stored it
> locally. The Relayer's HostIO process reads this token at startup and uses
> it as its identity. Without it, the Relayer runs but is unclaimed — storage
> operations will not persist to the network.

### 5. Verify

| Check | Expected |
|-------|----------|
| Dashboard loads at `http://localhost:8888` | Claimed / owned state — not the onboarding wizard |
| S3 endpoint answers | `curl -s http://localhost:9000` returns an XML response |

Point any S3-compatible client at `http://localhost:9000` to start storing
objects. The dashboard's **Settings > S3 Credentials** page shows the access
key and secret key your client needs.

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8888 | HTTP | Web dashboard |
| 9000 | HTTP | S3 API |
| 9443 | HTTPS | S3 API (active after installing a TLS certificate via Settings > Certificates) |

All three are configurable through the `.env` file.

## Updating

```bash
docker compose pull
docker compose up -d
```

Your data lives in a Docker-managed volume (`relayer_data`) and survives
image updates.

## Upgrading from a bind-mount install

If you previously ran the Relayer with a bind-mount volume
(`- ./data:/relayer`), the boot guard will detect the existing database and
refuse to start against an empty named volume. Either:

- **Keep the bind-mount** — change the volume line back to your host path.
- **Migrate** — copy the bind-mount contents into the `relayer_data` volume
  while the container is stopped.

If the old install used a custom path (not `./data`), set
`LEGACY_DATA_PATH=/your/old/path` in your `.env`.

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

## License

[Apache-2.0](LICENSE)
