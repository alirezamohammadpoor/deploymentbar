import { ListChecks } from "@phosphor-icons/react/dist/ssr/ListChecks";
import { CursorClick } from "@phosphor-icons/react/dist/ssr/CursorClick";
import { Lightning } from "@phosphor-icons/react/dist/ssr/Lightning";
import { Terminal } from "@phosphor-icons/react/dist/ssr/Terminal";
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
    title: "Every deployment, one place",
    body: "All projects. All environments. Production, preview, dev. Filtered, sorted, instant.",
  },
  {
    icon: CursorClick,
    title: "One click to action",
    body: "Open in Vercel. Copy URLs. View logs. Trigger redeploys. All from your menubar.",
  },
  {
    icon: Lightning,
    title: "Real-time, always",
    body: "10-second polling. Know about failures before your users do.",
  },
  {
    icon: Terminal,
    title: "Build logs on demand",
    body: "Full logs, one click. Jump to errors instantly.",
  },
  {
    icon: AppleLogo,
    title: "Native macOS",
    body: "Lightweight SwiftUI. Fast launch. Respects your system.",
  },
  {
    icon: ShieldCheck,
    title: "Secure by default",
    body: "OAuth with Vercel. No tokens stored. Your permissions.",
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
