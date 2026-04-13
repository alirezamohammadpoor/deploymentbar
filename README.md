# DeployBar

[![Build](https://github.com/alirezamohammadpoor/deploymentbar/actions/workflows/build.yml/badge.svg)](https://github.com/alirezamohammadpoor/deploymentbar/actions/workflows/build.yml)
[![Web](https://github.com/alirezamohammadpoor/deploymentbar/actions/workflows/web.yml/badge.svg)](https://github.com/alirezamohammadpoor/deploymentbar/actions/workflows/web.yml)

A native macOS menu bar application for monitoring Vercel deployments in real-time.

## Download

Grab the latest release: [github.com/alirezamohammadpoor/deploymentbar/releases/latest](https://github.com/alirezamohammadpoor/deploymentbar/releases/latest)

Requires macOS 14.0+.

## Features

- Real-time deployment monitoring from the menu bar
- GitHub CI check status on deployments
- Desktop notifications for ready/failed deployments
- Quick actions: copy URL, open in browser, view on Vercel, redeploy
- Filter by project, environment, or branch
- OAuth2 with PKCE authentication
- Adaptive polling (5s during active builds, 30s+ otherwise)

## Development

```bash
# Build
xcodebuild -project VercelBar.xcodeproj -scheme VercelBar -configuration Debug build

# Run tests
xcodebuild -project VercelBar.xcodeproj -scheme VercelBarTests -configuration Debug test

# Web landing page
cd web && bun run dev
```

See [CLAUDE.md](CLAUDE.md) for architecture details.
