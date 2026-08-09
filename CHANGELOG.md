# Changelog

## [0.1.0] — 2026-08-09

Initial release of the XNS Relayer quickstart.

- Single-service Docker Compose for the XNS Relayer
  (`releases.scpri.me/xns-relayer:beta-latest`), running unprivileged with a
  Docker-managed `relayer_data` volume.
- `.env.example` with port overrides, plus a `.gitignore` so a working `.env`
  can never be committed.
- README walkthrough: clone, `docker compose up`, claim the Relayer via the
  claim link shown in the welcome dialog, verify the dashboard and S3 endpoint.
- README sections on port exposure on public hosts, pinning the image tag, and
  what needs privileged access ("Storage and disks").
- `SECURITY.md` with a private vulnerability-reporting address.
- Apache-2.0 license (canonical text).
- CONTRIBUTING and PR template directing contributors to GitLab.
- `scripts/verify-public-hygiene.sh` — pre-mirror gate asserting no live `.env`,
  no internal references, the public image channel, and a byte-exact licence.
