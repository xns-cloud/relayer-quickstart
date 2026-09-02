# XNS compared to S3, R2, B2, Wasabi, Storj and self-hosted MinIO

Object storage comparisons are usually written by whoever wins them. This one
names where XNS loses, because a comparison you cannot check is worth nothing
and a comparison with no losing rows is not a comparison.

**Every figure below was re-fetched from the provider's own source on
2026-09-02.** Each row says where it came from, so you can re-run the check
rather than trust the table. Prices change; a copy of this file you did not
fetch yourself may be stale.

---

## The unit trap — read this before comparing any two cells

Providers do not agree on what a terabyte is, and the difference is 7%.

- **XNS** bills in decimal: 1 TB = 1000 GB. Stated at
  [`xns.tech/pricing.json`](https://xns.tech/pricing.json) (`decimal_convention`).
- **AWS** bills in binary. Its Price List API sets the "first 50 TB" S3 Standard
  tier boundary at `endRange: 51200`, which is 50 × 1024 — so AWS's "GB" is a
  GiB, and its "TB" is a TiB.
- **Wasabi** divides by 1024 in its own published derivation
  ($7.99 ÷ 1024 = $0.0078/GB), so its TB is a TiB too.
- **Storj** states GB and GB-months and bills decimal.
- **Cloudflare R2** and **Backblaze B2** quote per-GB and per-TB decimal.

Where a table below shows a per-TB figure, it uses **that provider's own
convention**, because that is what your invoice will use. Converting everyone
to one convention produces numbers no provider will ever bill you.

---

## List prices

| Provider | Storage per TB-month | Egress | Minimum retention | Other floors |
|---|---|---|---|---|
| **XNS** | **$6.00** (decimal TB) | **$0, uncapped** | 30 days, no early-delete fee | None |
| Backblaze B2 | $6.95 | Free up to 3× stored, then $0.01/GB | **None** | None; first 10 GB free |
| Storj (Standard) | $7.00 | $7.00/TB, no free allowance | 30 days | — |
| Wasabi (Pay-as-you-go) | $7.99 (binary TB) | "Free", capped 1:1 against stored volume | **90 days** | 1 TB monthly minimum; 4 KB minimum billable object |
| Cloudflare R2 (Standard) | $15.00 | **Free, uncapped** | None | Class A $4.50/million, Class B $0.36/million operations |
| AWS S3 Standard | $23.55 (binary TB, us-east-1, first 50 TB) | $0.09/GB after 100 GB/month free | None on Standard | — |
| Self-hosted MinIO | $0 software | $0 to the software | None | Your hardware, power, replication and staff |

Sources, all accessed 2026-09-02:
[XNS](https://xns.tech/pricing.json) ·
[B2](https://www.backblaze.com/cloud-storage/pricing) ·
[Storj](https://storj.dev/dcs/pricing/simplified) ·
[Wasabi](https://wasabi.com/pricing/faq) ·
[R2](https://developers.cloudflare.com/r2/pricing/) ·
[AWS](https://aws.amazon.com/s3/pricing/) (figures read from the
[Price List API](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonS3/current/us-east-1/index.json),
`publicationDate: 2026-08-31`, which is what the pricing page renders from).

> **A note on the B2 figure, so nobody "corrects" it.** Backblaze's pricing page
> currently contains both numbers. Its intro prose says "$5/TB/month"; the page's
> own live price constant — the one its calculator renders from — reads
> `"b2-monthly-tb": 6.95`. The table above uses **$6.95**, because that is the
> number the site actually computes with. If you check and see $5 in the prose,
> you have found the same stale sentence, not an error here.

---

## Worked example: store 10 TB, read all of it back once

| Provider | Storage | Egress | Month |
|---|---|---|---|
| **XNS** | $60.00 | $0.00 | **$60.00** |
| Backblaze B2 | $69.50 | $0.00 (1× is inside the 3× allowance) | $69.50 |
| Wasabi | $79.90 | $0.00 (1× is inside the 1:1 cap) | $79.90 |
| Storj | $70.00 | $70.00 | $140.00 |
| Cloudflare R2 | $150.00 | $0.00 | $150.00 + operations |
| AWS S3 Standard | $235.52 | $912.60 | $1,148.12 |

Arithmetic: list price × 10, plus egress. AWS egress is 10,240 GB less the 100 GB
monthly free allowance, at $0.09/GB. R2's total excludes Class A and Class B
operation charges, which depend on your object count and read pattern rather than
your byte count — at a million reads that is $0.36, at 300 million it is $108.

**Change the read pattern and the ranking changes.** Read your 10 TB back *ten*
times in a month and B2's 3× allowance is exhausted (70 TB billable at $0.01/GB
≈ $700), Wasabi's 1:1 guideline is exceeded by tenfold, Storj bills $700 of
egress, and AWS bills about $7,980 of egress on top of its storage. XNS and R2
bill the same as the table above. That divergence — not the storage rate — is
the actual argument.

---

## What "free egress" means at each provider

Five of the seven use the phrase. They do not mean the same thing.

- **XNS** — $0, no ratio, no cap, no review clause. The terms current between
  `effective_date` and `valid_through` in
  [`pricing.json`](https://xns.tech/pricing.json).
- **Cloudflare R2** — free and uncapped, genuinely. Cloudflare monetizes the
  operations instead: $4.50 per million Class A and $0.36 per million Class B.
- **Backblaze B2** — free up to 3× your average monthly stored volume, then
  $0.01/GB. A published overage price, not an enforcement threat.
- **Wasabi** — free while monthly egress stays at or below your stored volume.
  Their own words: *"If your use case exceeds the guidelines of our free egress
  policy on a regular basis, we reserve the right to limit or suspend your
  service."* There is no overage rate; the remedy is enforcement.
- **Storj** — no free egress at all. $7.00/TB out, on top of $7.00/TB stored.
- **AWS** — $0.09/GB after 100 GB/month, tiering down to $0.05/GB above 150 TB.

---

## Where XNS loses

- **Backblaze B2 has no minimum retention. XNS has 30 days.** If your objects
  live for hours or days, B2 bills you for what you stored and XNS bills you for
  30 days of it. For short-lived data B2 is cheaper than XNS regardless of the
  headline rate, and it is not close.
- **Cloudflare R2's free egress is the same promise as ours, from a much larger
  network.** If your workload is read-heavy with few operations, R2 competes
  directly on the thing we lead with, backed by Cloudflare's edge. Where R2 gets
  expensive is per-operation cost on many small objects, not bytes out.
- **AWS wins on everything that is not price.** Roughly 100 compliance programs,
  39 regions, 124 availability zones, an integration surface nobody else has, and
  it *defines* the S3 API the rest of us implement. If your blocker is a
  compliance attestation or a specific regional requirement, the price comparison
  above is irrelevant to your decision.
- **Storj is genuinely distributed too.** Reed-Solomon erasure coding across tens
  of thousands of operator-run nodes, no replication, customer-selectable region.
  Anyone telling you XNS is "the only distributed option" is wrong. Storj's
  weaknesses are elsewhere — a central Satellite that holds all metadata and node
  selection, region selection that is not self-serve, and a liability cap of the
  lesser of $50 and twelve months of fees.
- **Wasabi and B2 have longer operating histories and audited compliance
  postures.** Wasabi holds ISO 27001:2022. If your procurement process requires a
  vendor with years of attestations behind it, that is a real gate and we are the
  newer name.
- **Self-hosted MinIO is free.** If you already own the hardware, the rack and
  the staff to run it, no hosted price beats $0. What you take on is replication,
  durability engineering, capacity planning and the pager.
- **Our S3 gateway is pre-release.** This quickstart pulls from the public beta
  channel. That is the honest state of the software, and it is a reason to test
  before you commit a workload.

## Where XNS wins

- **$0 egress with no ratio, no cap and no review clause**, which among the
  cheap-storage providers is R2's position and nobody else's — and R2 charges
  per operation where we do not.
- **A rate card that fits in one line.** $6.00 per TB per month, $0 egress
  uncapped, 30-day minimum retention, no early-delete fee. No minimum object
  size, no monthly account minimum, no retrieval fee, no per-operation charge,
  no storage class to pick wrong.
- **No minimum billable object size.** Wasabi bills a 4 KB floor per object and
  AWS's cheaper storage classes bill a 128 KB floor (both read 2026-08-19, see
  Method). On a corpus of small objects those floors dominate the bill.
- **Placement you choose** — by geography, provider or named host, rather than
  wherever the vendor puts it.
- **Standard S3 clients today.** Current boto3, AWS CLI and rclone work against
  it. No SDK fork, no special client. See
  [S3 compatibility](https://xns.tech/s3-compatibility).
- **Plain dollars.** No wallet, no token, no exchange step between you and your
  invoice.

## On self-hosting MinIO

For years the answer to "S3-compatible, on my own hardware" was MinIO. As of
2026-09-02 `github.com/minio/minio` is **archived** — read-only, last push
2026-04-24, 61,374 stars. Verified via the GitHub API on the date above.

An archived repository still runs. It does not get security fixes, and it does
not get a maintainer. If you are choosing where to put the next five years of
data, that is worth knowing before you choose, whichever way you then decide.

---

## Method, and how to check this yourself

Storage rates, egress terms and minimum-retention periods were re-read from each
provider's own domain on **2026-09-02**, not from a comparison site and not from
memory. Where a provider's public page renders its prices in JavaScript — AWS and
Backblaze both do — the figure was read from the machine-readable source that
page renders from, and that source is linked above.

The secondary floors — Wasabi's 4 KB minimum billable object, its 1 TB monthly
minimum, and AWS's 128 KB floor on its cheaper storage classes — come from a
primary-source sweep dated **2026-08-19** and were not re-fetched on 2026-09-02.
They are flagged separately rather than folded into the later date, because a
figure is only as good as the day someone actually looked.

Two corrections this research forced, recorded so they are not repeated:

1. **Wasabi is $7.99/TB-month, not $6.99.** The raise took effect 2026-07-01.
   Most published comparisons still carry the old number.
2. **Backblaze B2 is $6.95/TB-month, not $5.** See the note under the price
   table.

Competitor names and marks belong to their respective owners. Every price on this
page is a public list price; negotiated, reserved-capacity and volume rates are
not public at any of these providers, including ours.

This file is checked into
[`relayer-quickstart`](https://github.com/xns-cloud/relayer-quickstart) so it
carries a date and a diff history. If a figure here is wrong,
[open an issue](https://github.com/xns-cloud/relayer-quickstart/issues) — that is
a faster correction path than a marketing page.
