# Security Policy

## Our Security Commitment

OpenKimo is built on a foundation of **mandatory isolation**. Every agent session runs inside a dedicated Docker container with restricted cgroups. We will never execute untrusted code outside of a sandbox, and we treat any escape from the container boundary as a critical security issue.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

At this stage of the project we only support the most recent release. Please upgrade to the latest Docker image before reporting a vulnerability against an older version.

## Reporting a Vulnerability

**Please do not open public issues for security bugs.**

1. **Email** – Send details to `security@openkimo.dev` (GPG key available on request).
2. **GitHub Security Advisory** – Open a [private advisory](https://github.com/openkimo/openkimo/security/advisories/new) if you prefer to keep the discussion on GitHub.

Include the following if possible:
- A minimal reproduction step or proof-of-concept.
- The OpenKimo version (image digest) you tested against.
- Your assessment of impact (sandbox escape, data leak, DoS, etc.).
- Any suggested mitigation or patch.

We aim to acknowledge receipt within **48 hours** and ship a fix or detailed response within **7 days** for critical issues. Non-critical issues are typically resolved within **30 days**.

## Disclosure Policy

- We follow a **coordinated disclosure** model.
- We will notify you before any public announcement and credit you (unless you wish to remain anonymous).
- If a fix requires a breaking change, we will ship a patched release first and document the breakage in the release notes.

## Known Security Limitations & Notes

- **Docker socket exposure**: The gateway container mounts the host Docker socket (`/var/run/docker.sock`) to orchestrate sandbox containers. Anyone with access to the gateway container can create privileged containers on the host. Run OpenKimo on a dedicated host or VM; do not expose the gateway to untrusted networks.
- **Root inside the sandbox**: The sandbox container currently runs as `root` internally so that package installation and kernel debugging work out of the box. The container is still unprivileged (`--privileged=false`), but a kernel vulnerability or Docker escape could allow host compromise.
- **No network egress filtering by default**: Sandboxes can reach the public internet. If your use-case involves sensitive internal services, add custom `iptables` rules or Docker network policies.
- **LLM prompt injection**: The framework itself cannot prevent a malicious prompt from tricking the LLM into emitting harmful shell commands. We mitigate this with the dangerous-command interceptor, but defense-in-depth (output scanning, human-in-the-loop) is recommended for high-risk deployments.
- **Secrets in environment variables**: API keys are passed via `.env`. Ensure the file has `0600` permissions and is never committed to Git.

## Threat Model (High-Level)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   End User      │────▶│   Gateway       │────▶│   Sandbox       │
│   (Browser/CLI) │     │   (Docker)      │     │   (Docker)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │                        │
                               │  Docker Socket         │  CPU/Mem/Disk/PID
                               │  (host /var/run/…)     │  cgroups
                               ▼                        ▼
                         ┌─────────────────┐     ┌─────────────────┐
                         │   Host Kernel   │     │   Host Kernel   │
                         │   & Docker      │     │   & Docker      │
                         └─────────────────┘     └─────────────────┘
```

- **Agent code** is confined to the Sandbox container.
- **Gateway** is a separate container that talks to the LLM APIs and spawns sandboxes via the host Docker daemon.
- **Host compromise** would require a Docker or kernel escape from the sandbox, or unauthorized access to the gateway container + Docker socket.

## Security Hardening Checklist

Before running OpenKimo in production:

- [ ] Run on a dedicated host or VM (not alongside other sensitive workloads).
- [ ] Restrict gateway port access with a firewall or reverse proxy.
- [ ] Rotate LLM API keys regularly and scope them to the minimum required permissions.
- [ ] Review and customize the `dangerous_commands` blocklist in `config/security.yml`.
- [ ] Enable Docker Content Trust and pin image digests in `docker-compose.yml`.
- [ ] Consider adding an additional network policy (e.g., `docker network create --internal`) if sandboxes do not need outbound internet.
