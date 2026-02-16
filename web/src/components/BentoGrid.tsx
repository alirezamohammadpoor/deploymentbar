import { ListChecks } from "@phosphor-icons/react/dist/ssr/ListChecks";
import { CursorClick } from "@phosphor-icons/react/dist/ssr/CursorClick";
import { CheckCircle } from "@phosphor-icons/react/dist/ssr/CheckCircle";
import { Funnel } from "@phosphor-icons/react/dist/ssr/Funnel";
import { AppleLogo } from "@phosphor-icons/react/dist/ssr/AppleLogo";
import { ShieldCheck } from "@phosphor-icons/react/dist/ssr/ShieldCheck";
import type { Icon } from "@phosphor-icons/react/dist/lib/types";

interface Feature {
  icon: Icon;
  title: string;
  body: string;
}

const features: Feature[] = [
  {
    icon: ListChecks,
    title: "Every deployment in one place",
    body: "All projects. All environments. CI check status at a glance. Filtered, sorted, instant.",
  },
  {
    icon: CursorClick,
    title: "One-click actions",
    body: "Copy URLs. Open in browser. Open in Vercel. Trigger redeploys. All from your menu bar.",
  },
  {
    icon: CheckCircle,
    title: "CI check status",
    body: "See GitHub Actions results inline. Green, yellow, red — know if checks passed before you merge.",
  },
  {
    icon: Funnel,
    title: "Smart filtering",
    body: "Filter by environment and by project. Find the deployment you need in seconds.",
  },
  {
    icon: AppleLogo,
    title: "Native macOS",
    body: "Lightweight SwiftUI. Fast launch. Under 20MB memory.",
  },
  {
    icon: ShieldCheck,
    title: "Secure by default",
    body: "OAuth with Vercel (read-only scope). Tokens stored in macOS Keychain. Nothing leaves your machine.",
  },
];

export function BentoGrid() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-6 py-24">
      <h2 className="mb-12 text-center text-3xl font-medium text-text-primary md:text-[32px]">
        Everything you need.{" "}
        <span className="text-text-secondary">Nothing you don&apos;t.</span>
      </h2>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {features.map((feature) => {
          const Icon = feature.icon;
          return (
            <div
              key={feature.title}
              className="bento-card rounded-xl border border-card-border bg-card-bg p-8"
            >
              <Icon size={32} weight="regular" className="mb-4 text-accent-blue" />
              <h3 className="mb-3 text-lg font-medium text-text-primary">
                {feature.title}
              </h3>
              <p className="text-sm leading-relaxed text-text-secondary">
                {feature.body}
              </p>
            </div>
          );
        })}
      </div>
    </section>
  );
}
