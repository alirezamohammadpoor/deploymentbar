import type { ReactNode } from "react";
import { SectionLabel } from "./ui/primitives";

const svg = {
  width: 22,
  height: 22,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.5,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

const ICONS: Record<string, ReactNode> = {
  window: (
    <svg {...svg}>
      <rect x="3" y="6" width="18" height="12" rx="1.5" />
      <path d="M3 9.5h18" />
    </svg>
  ),
  lock: (
    <svg {...svg}>
      <rect x="6" y="11" width="12" height="10" rx="1.5" />
      <path d="M8.5 11V8a3.5 3.5 0 0 1 7 0v3" />
    </svg>
  ),
  bolt: (
    <svg {...svg}>
      <path d="M13 3 6 13h5l-1 8 8-11h-5l1-7Z" />
    </svg>
  ),
  download: (
    <svg {...svg}>
      <path d="M12 3v12" />
      <path d="M7 10l5 5 5-5" />
      <path d="M5 19h14" />
    </svg>
  ),
};

const CARDS = [
  {
    icon: "window",
    title: "Native SwiftUI",
    desc: "SwiftUI and AppKit — a real Mac app, not a web view or Electron shell.",
  },
  {
    icon: "lock",
    title: "Secure by default",
    desc: "Read-only OAuth scope. Tokens live in the macOS Keychain, never on disk.",
  },
  {
    icon: "bolt",
    title: "Lightweight",
    desc: "Under 20 MB. Quiet, adaptive polling that respects your battery.",
  },
  {
    icon: "download",
    title: "Auto-updating",
    desc: "Ships new versions itself via Sparkle. Always current, nothing to re-download.",
  },
];

const BADGES = ["Swift", "SwiftUI", "Keychain", "OAuth", "Sparkle"];

export function Platform() {
  return (
    <section className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6 py-[88px]">
        <div className="grid grid-cols-1 gap-12 md:grid-cols-12 md:items-start md:gap-6">
          {/* left — label, headline, body, tech badges */}
          <div className="md:col-span-5">
            <SectionLabel label="Platform" />
            <h2 className="mt-6 text-[2rem] font-medium leading-[1.08] tracking-[-0.03em] sm:text-[2.75rem]">
              <span className="block text-text-primary">Built for macOS,</span>
              <span className="block text-text-secondary">and nothing else.</span>
            </h2>
            <p className="mt-6 max-w-md text-[15px] leading-relaxed text-text-secondary">
              Everything you expect from a native Mac app — and nothing you
              don’t. No web view, no account wall, no bloat.
            </p>
            <div className="mt-7 flex flex-wrap gap-2">
              {BADGES.map((b) => (
                <span
                  key={b}
                  className="rounded-[4px] border border-hairline px-2 py-1 font-mono text-[10px] text-text-secondary"
                >
                  {b}
                </span>
              ))}
            </div>
          </div>

          {/* right — hairline card stack with thin line icons */}
          <div className="space-y-3 md:col-start-7 md:col-span-6">
            {CARDS.map((c) => (
              <div
                key={c.title}
                className="flex gap-3.5 rounded-[10px] border border-hairline bg-surface-2 p-[18px]"
              >
                <span className="mt-0.5 shrink-0 text-text-secondary">
                  {ICONS[c.icon]}
                </span>
                <div>
                  <h3 className="text-[15px] font-medium text-text-primary">
                    {c.title}
                  </h3>
                  <p className="mt-1 text-[13px] leading-relaxed text-text-secondary">
                    {c.desc}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
