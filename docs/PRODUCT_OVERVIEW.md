# VercelBar - Product Overview

## Executive Summary

VercelBar is a native macOS menu bar application that allows developers to monitor their Vercel deployments without leaving their workflow. It sits unobtrusively in the menu bar and provides real-time deployment status updates with desktop notifications.

**Target User**: Developers and teams who deploy web applications on Vercel and want instant visibility into deployment status without context-switching to the Vercel dashboard.

---

## Core Value Proposition

1. **Always-visible deployment status** - One glance at the menu bar shows if builds are running
2. **Instant notifications** - Know immediately when deployments succeed or fail
3. **Zero context switching** - No need to open browser or check Vercel dashboard
4. **Native experience** - Fast, lightweight, integrates with macOS

---

## Current Features

### Authentication
- **OAuth integration** with Vercel (industry-standard secure flow)
- **Personal Access Token** support as fallback for users who prefer it
- Automatic token refresh (seamless re-authentication)

### Deployment Monitoring
- Real-time polling of deployment status (configurable 10s - 5min intervals)
- **Adaptive polling**: Faster updates (5s) when builds are actively running
- Filter deployments by specific projects
- View deployment details: project name, branch, status, timestamp

### Notifications
- Desktop notifications when deployments complete (ready) or fail
- Configurable: users can enable/disable ready and failed notifications independently
- Click notification to open deployment URL in browser

### User Preferences
- Choose preferred browser for opening links
- Launch at login option
- Project filtering to focus on specific projects
- Customizable polling interval

---

## User Experience Flow

```
1. Install & Launch
   └── App appears in menu bar (no dock icon)

2. Sign In
   └── Click menu bar icon → "Sign in with Vercel" → Browser OAuth flow → Redirects back

3. Monitor
   └── Icon pulses during active builds
   └── Click to see deployment list with status indicators
   └── Filter by All / Production / Preview

4. Get Notified
   └── Desktop notification appears when build completes
   └── Click notification → Opens deployment URL

5. Configure
   └── Settings accessible from menu
   └── Toggle notifications, select browser, filter projects
```

---

## Current Limitations & Known Gaps

### Feature Gaps
| Gap | Impact | Notes |
|-----|--------|-------|
| No team switching | Users with multiple Vercel teams must sign out/in | Currently uses first team discovered |
| No deployment actions | Can only view, not trigger redeploys or rollbacks | Read-only experience |
| No deployment logs | Must open browser to see build logs | Missed opportunity for deeper integration |
| Single account only | Cannot monitor multiple Vercel accounts | Limits enterprise users |
| macOS only | No Windows/Linux support | Limits addressable market |

### UX Improvements Needed
| Issue | Details |
|-------|---------|
| No onboarding | Users dropped into empty state after install |
| Limited empty states | "No recent deployments" doesn't guide next steps |
| No search/filter by name | Must scroll through deployments |
| No keyboard shortcuts | Mouse-only interaction |
| Settings feel basic | Functional but not polished |

### Technical Debt
- Some test coverage gaps (placeholder tests exist)
- No crash reporting or analytics
- No automatic updates mechanism

---

## Competitive Landscape

| Solution | Pros | Cons |
|----------|------|------|
| **Vercel Dashboard** | Full-featured, official | Requires browser, context switch |
| **Vercel CLI** | Powerful, scriptable | Terminal-based, not passive monitoring |
| **GitHub Actions notifications** | Integrated with PRs | Not Vercel-specific, delayed |
| **Slack/Discord integrations** | Team visibility | Noisy, mixed with other notifications |
| **VercelBar (this app)** | Native, always-visible, focused | macOS only, read-only |

---

## Potential Roadmap Ideas

### Quick Wins (Low effort, High impact)
1. **Improved empty states** - Guide users when no deployments exist
2. **Keyboard shortcut** to open/close menu (global hotkey)
3. **Sound options** for notifications
4. **Deployment count badge** on menu bar icon

### Medium-Term Enhancements
1. **Team switcher** - Support users with multiple Vercel teams
2. **Quick actions** - Redeploy, rollback, promote to production
3. **Build logs preview** - Show recent log lines without opening browser
4. **Search/filter** - Find deployments by project name or branch
5. **Deployment history** - See past deployments beyond current polling window

### Strategic Opportunities
1. **Multi-account support** - Enterprise users with multiple organizations
2. **Windows/Linux versions** - Expand addressable market (Electron or native)
3. **iOS companion app** - Monitor deployments on mobile
4. **Team features** - See who triggered deployment, team activity feed
5. **Analytics dashboard** - Deployment frequency, success rates, build times

---

## Success Metrics to Consider

### Engagement
- Daily/Weekly active users
- Average session duration (menu open time)
- Notifications clicked vs. dismissed

### Retention
- D1, D7, D30 retention rates
- Churn after trial period (if applicable)

### Feature Adoption
- % users with notifications enabled
- % users filtering by project
- % users using personal token vs. OAuth

### Quality
- Crash-free session rate
- Authentication success rate
- API error rates

---

## Technical Architecture Summary

- **Platform**: Native macOS app (Swift/SwiftUI)
- **Minimum OS**: macOS 14.0 (Sonoma)
- **Authentication**: OAuth 2.0 with PKCE (secure, no secrets exposed)
- **Data sync**: Polling-based (not websockets) - simple, reliable
- **Storage**: Local filesystem for tokens, UserDefaults for preferences
- **Dependencies**: Zero external dependencies (Apple frameworks only)

The codebase is well-structured with clear separation between UI, services, and API layers. Adding new features should be straightforward for developers familiar with Swift/SwiftUI.

---

## Open Questions for Product Strategy

1. **Monetization**: Is this a free tool, freemium, or paid? What's the business model?
2. **Target audience**: Individual developers, small teams, or enterprise?
3. **Vercel relationship**: Independent tool or potential for official partnership/acquisition?
4. **Platform priority**: Double down on macOS or expand to other platforms?
5. **Feature depth vs. breadth**: Stay focused on monitoring or expand to deployment management?

---

*Document prepared for product planning purposes. Technical details available in CLAUDE.md.*
