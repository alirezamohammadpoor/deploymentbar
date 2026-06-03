"use client";

import { useState } from "react";
import { SectionLabel } from "./ui/primitives";

const FAQS: { q: string; a: string }[] = [
  {
    q: "How much time will this save me?",
    a: "Instead of switching to your browser, finding the Vercel tab, and navigating to your project, every deployment status sits in your menu bar. Most developers save 10+ context switches a day.",
  },
  {
    q: "Is it secure?",
    a: "Yes. Deploymentbar uses Vercel’s official OAuth2 with PKCE — a read-only scope, with tokens stored in the macOS Keychain. Nothing leaves your machine.",
  },
  {
    q: "How long does setup take?",
    a: "Under a minute. Install the app, click Sign in with Vercel, authorize, and your deployments appear immediately.",
  },
  {
    q: "macOS says the app is “damaged.” How do I open it?",
    a: "During the public beta the app isn’t notarized by Apple yet, so macOS quarantines it on first launch. Right-click the app and choose Open, or run xattr -dr com.apple.quarantine /Applications/VercelBar.app in Terminal once. It launches normally after that, and updates install automatically.",
  },
  {
    q: "What happens after the beta?",
    a: "It’s free during the public beta. If we introduce pricing later, early users get a generous discount.",
  },
  {
    q: "What if I need help?",
    a: "Reach out on GitHub Issues — we’re a small team and we respond fast.",
  },
];

export function FAQ() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6 py-[88px]">
        <div className="max-w-2xl">
          <SectionLabel label="FAQ" />
          <h2 className="mt-6 text-[2rem] font-medium leading-[1.08] tracking-[-0.03em] text-text-primary sm:text-[2.75rem]">
            Questions?
          </h2>
        </div>

        <div className="mt-10 border-t border-hairline">
          {FAQS.map((f, i) => {
            const isOpen = open === i;
            return (
              <div key={f.q} className="border-b border-hairline">
                <button
                  type="button"
                  onClick={() => setOpen(isOpen ? null : i)}
                  className="flex w-full items-center justify-between gap-4 py-5 text-left"
                >
                  <span
                    className={`text-[16px] transition-colors ${
                      isOpen ? "text-text-primary" : "text-text-secondary"
                    }`}
                  >
                    {f.q}
                  </span>
                  <span
                    aria-hidden
                    className="shrink-0 font-mono text-[18px] leading-none text-text-dim"
                  >
                    {isOpen ? "−" : "+"}
                  </span>
                </button>
                <div
                  className={`grid transition-[grid-template-rows,opacity] duration-200 ease-[var(--ease-out)] ${
                    isOpen
                      ? "grid-rows-[1fr] opacity-100"
                      : "grid-rows-[0fr] opacity-0"
                  }`}
                >
                  <div className="overflow-hidden">
                    <p className="max-w-2xl pb-6 text-[14px] leading-relaxed text-text-secondary">
                      {f.a}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
