# Mobile QR pairing (self-hosted Blazebuzz)

How NIP-AB desktop → Android pairing works on FOXTROT, why “Could not reach
the pairing relay” shows up on a home LAN, and how to fix it.

**Audience:** Blazenetic operators on FOXTROT (CachyOS).  
**Status:** Diagnosed 2026-07-30; config/network fix required for store Android.  
**Related:** [RUNBOOK.md](RUNBOOK.md) · [NEXT-STEPS.md](NEXT-STEPS.md) · [AGENTS.md](AGENTS.md)

---

## TL;DR

| Item | Fact |
|------|------|
| Symptom | Phone: *Could not reach the pairing relay…* after scanning desktop QR |
| Root cause | QR embeds `ws://localhost:3000` → phone dials **itself**, not FOXTROT |
| Not the main issue | OPNsense (same-LAN clients do not need WAN rules for localhost) |
| Store Android needs | Public or mesh **`wss://` hostname** + matching `RELAY_URL` |
| Pure LAN `ws://10.x` | Fine for desktop; **rejected** by release mobile validation |

---

## What the QR actually does

1. Desktop **Start pairing** builds a `nostrpair://…` URI that embeds the
   **pairing WebSocket URL** (from the active community’s relay, or from the
   relay’s NIP-11 `pairing_relay_url` if set).
2. The phone scans that URI and opens a WebSocket to that URL with ephemeral
   keys (NIP-AB kind `24134`).
3. After SAS confirmation, desktop encrypts a payload containing:
   - `relayUrl` — HTTP(S) origin of the community (what the phone keeps)
   - `nsec` / `pubkey` — the desktop identity
4. The store Android app then **validates** that community URL before saving it.

Desktop and phone must both reach the **same** pairing relay, and the phone
must later reach a **production-acceptable** community origin.

---

## Diagnosis on FOXTROT (2026-07-30)

| Check | Result |
|-------|--------|
| Relay listening | `0.0.0.0:3000` (LAN-reachable if you use the right host) |
| Workstation LAN IP | `10.1.20.100` (`enp38s0`) |
| `.env` `RELAY_URL` | `ws://localhost:3000` |
| Desktop community | `ws://localhost:3000` (localStorage) |
| NIP-11 `pairing_relay_url` | unset → pairing uses the main community URL |
| Dedicated `buzz-pair-relay` | not running (optional; not required for open main-relay pairing) |

**Root cause of the phone error:** the QR encodes something like
`relay=ws%3A%2F%2Flocalhost%3A3000`. On the phone, `localhost` is the **phone
itself**, not FOXTROT. Connection fails →

> Could not reach the pairing relay. Check your internet connection and VPN, then try again.

This is **not** primarily OPNsense (same-WiFi clients never hit the WAN).
OPNsense only matters if you later expose a public hostname (NAT / port
forward / hairpin) or if you have client isolation between WiFi and wired LAN.

---

## Why “just use the LAN IP” is not enough (store app)

Even if the QR said `ws://10.1.20.100:3000`, the **release** Buzz Android app
still enforces:

| Rule | Source |
|------|--------|
| Community URL must be **HTTPS** (not plain HTTP) | `pairing_provider.dart` `_validateRelayUrl` |
| No **private IP literals** (`10/8`, `192.168/16`, `172.16/12`, CGNAT `100.64/10`, …) | same |
| Pairing WebSocket is plain `ws://` unless you terminate TLS | Android cleartext defaults |

So a pure home-LAN `ws://10.x` community works for **desktop + debug mobile
builds**, but **not** for the Play Store / release APK as shipped upstream.

---

## Recommended setups (pick one)

### A. Public HTTPS hostname (best for store Android)

You need a DNS name the phone can resolve and a certificate Android trusts
(Let’s Encrypt or commercial CA).

**Options that fit OPNsense + FOXTROT:**

1. **Cloudflare Tunnel** (`cloudflared`) to `http://127.0.0.1:3000`  
   - No inbound port open on OPNsense  
   - Free TLS at `wss://buzz.yourdomain.com`
2. **OPNsense port forward 443 → FOXTROT** + reverse proxy (Caddy/nginx) with ACME  
3. **`deploy/compose` + Caddy** on a VPS (`BUZZ_COMPOSE_TLS=true`)  
   See [deploy/compose/README.md](../../deploy/compose/README.md)

Then:

```bash
# .env on the relay host
RELAY_URL=wss://buzz.example.com          # MUST match the public name clients use
BUZZ_BIND_ADDR=0.0.0.0:3000               # or behind the reverse proxy only
# optional dedicated pairing sidecar:
# BUZZ_PAIRING_RELAY_URL=wss://pairing.example.com
```

1. Restart the relay so NIP-42 challenges use the public URL.  
2. In the desktop app, **add / switch the community** to `wss://buzz.example.com`
   (do not leave `ws://localhost:3000` as the active community).  
3. Start pairing again and scan.

`RELAY_URL` and the community URL clients put in NIP-42 AUTH tags must agree.
If the phone authenticates as `wss://buzz.example.com` while the relay expects
`ws://localhost:3000`, AUTH fails with a different mobile error
(“pairing relay rejected authentication”).

### B. Tailscale / NetBird (private mesh + HTTPS)

1. Install Tailscale (or NetBird) on FOXTROT and the phone.  
2. Prefer a **hostname + HTTPS** endpoint (e.g. Tailscale Serve / MagicDNS +
   certs), not a raw `100.x` IP — private IP literals are rejected by the
   store app.  
3. Point desktop community + `RELAY_URL` at that `wss://…` name.  
4. Pair while both devices are on the mesh.

### C. Debug Flutter build (LAN only, developers)

Only if you build mobile yourself in **debug** (`kDebugMode`):

- Plaintext `localhost` is allowed for local emulator work.  
- Private IP community URLs are still **rejected** by `_validateRelayUrl`.  
- A **hostname** (mDNS / split DNS) over HTTP can work in debug; release still
  requires HTTPS.

```bash
# example only — not installed on FOXTROT by default
cd mobile
flutter run --dart-define=BUZZ_RELAY_URL=http://foxtrot.lan:3000
```

Agents: do not run `flutter run` / `flutter build` on this host unless the
human explicitly asks (see root AGENTS.md mobile rules).

---

## OPNsense checklist (when using a public or hairpinned name)

- [ ] Phone and FOXTROT not isolated (no AP/client isolation for that SSID)  
- [ ] If testing LAN→LAN by IP: allow TCP **3000** (or **443** if proxied) from
      WiFi VLAN to FOXTROT’s VLAN  
- [ ] Hairpin NAT / reflection if the phone uses the public hostname while on LAN  
- [ ] No captive portal blocking the phone  
- [ ] If using Cloudflare Tunnel: no WAN port forward needed  

Quick check from another LAN device (or phone browser):

```text
http://10.1.20.100:3000/health   → should return "ok"
```

If that fails, fix routing/firewall before pairing. If it works but the QR still
says `localhost`, fix the **community URL** (section A).

---

## Optional dedicated pairing relay

Production multi-tenant / membership-gated (NIP-43) relays often run
`buzz-pair-relay` and advertise it:

```bash
# pair-relay process
BUZZ_PAIR_RELAY_BIND_ADDR=0.0.0.0:5000
cargo run -p buzz-pair-relay

# main relay
BUZZ_PAIRING_RELAY_URL=wss://pairing.example.com
```

Desktop discovers this via NIP-11 `pairing_relay_url`. For a single open
self-hosted community, pairing on the **main** relay is enough **if** that
URL is phone-reachable over WSS.

---

## Quick “am I ready?” checklist

- [ ] Active desktop community is **not** `ws://localhost:3000` / `127.0.0.1`  
- [ ] Relay `RELAY_URL` matches that public (or mesh) `wss://` name  
- [ ] Phone can open the health URL over the same host (HTTPS in production)  
- [ ] Store app → TLS + non-private hostname  
- [ ] Start pairing **after** the community switch; old QR codes are useless  

---

## Fork notes

This investigation is **docs-only** on the Blazenetic fork. No product code
under `crates/` or `desktop/` was kept.

| Path | Role |
|------|------|
| `docs/blazenetic/MOBILE-PAIRING.md` | This note |
| `docs/blazenetic/RUNBOOK.md` | Troubleshooting row link |
| `docs/blazenetic/NEXT-STEPS.md` | Checklist item |
| `docs/blazenetic/AGENTS.md` | Pointer for agents |

These live under `docs/blazenetic/`, which is on the **protect list**
(`scripts/blazenetic/protect.list`). `just bb-sync` prefers “ours” for that
directory, so upstream merges should not wipe them.

A temporary desktop loopback-pairing guard was prototyped during diagnosis and
**reverted** so fork sync stays free of product-tree deltas. Re-implement
upstream (or as a small PR to `block/buzz`) if you want that UX later.

---

## Related

- [RUNBOOK.md](RUNBOOK.md) — daily start / stop  
- [CACHYOS.md](CACHYOS.md) — FOXTROT host notes  
- [SYNC.md](SYNC.md) — `bb-sync` and protected paths  
- Upstream NIP-AB: `crates/buzz-core/src/pairing/NIP-AB.md`  
- Helm pairing sidecar: `deploy/charts/buzz/README.md` § Device pairing relay  
