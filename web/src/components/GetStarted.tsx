import type { ReactNode } from "react";
import { SectionLabel } from "./ui/primitives";

const STEPS: { num: string; title: string; desc: string; frag: ReactNode }[] = [
  {
    num: "01",
    title: "Install",
    desc: "Download for macOS and drag it to your Applications folder.",
    frag: (
      <div className="flex items-center gap-2.5">
        <span className="flex h-7 w-7 items-center justify-center rounded-[4px] bg-surface-3 text-[11px] text-text-primary">
          ▲
        </span>
        <span className="font-mono text-text-dim">→</span>
        <span className="text-[13px] text-text-secondary">Applications</span>
      </div>
    ),
  },
  {
    num: "02",
    title: "Add your Vercel token",
    desc: "Create a personal access token on Vercel and paste it in — about 30 seconds.",
    frag: (
      <div className="w-full rounded-[6px] border border-hairline bg-surface-3 px-2.5 py-1.5 font-mono text-[12px] text-text-dim">
        vca_••••••••••••
      </div>
    ),
  },
  {
    num: "03",
    title: "Connect GitHub",
    desc: "Optional. Add a token to see CI check status on each deploy.",
    frag: (
      <div className="w-full space-y-1.5">
        <span className="inline-block rounded-full border border-hairline px-2 py-0.5 font-mono text-[9px] tracking-wider text-text-dim">
          OPTIONAL
        </span>
        <div className="rounded-[6px] border border-hairline bg-surface-3 px-2.5 py-1.5 font-mono text-[12px] text-text-dim">
          ghp_••••••••••••
        </div>
      </div>
    ),
  },
  {
    num: "04",
    title: "Watch deployments",
    desc: "Every deployment lands in your menu bar the moment it changes.",
    frag: (
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <span className="h-2 w-2 rounded-full bg-status-ready" />
          <span className="text-[13px] font-medium text-text-primary">
            web-app
          </span>
          <span className="font-mono text-[11px] text-text-dim">main</span>
        </div>
        <div className="text-[12px] text-text-secondary">Ready · CI passed</div>
      </div>
    ),
  },
];

export function GetStarted() {
  return (
    <section className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6 py-[88px]">
        <div className="max-w-2xl">
          <SectionLabel label="Get started" />
          <h2 className="mt-6 text-[2rem] font-medium leading-[1.08] tracking-[-0.03em] sm:text-[2.75rem]">
            <span className="block text-text-primary">
              From download to deployed,
            </span>
            <span className="block text-text-secondary">in four steps.</span>
          </h2>
          <p className="mt-6 max-w-md text-[15px] leading-relaxed text-text-secondary">
            Install the app, paste a Vercel token, and your deployments appear in
            the menu bar. GitHub is optional — add a token for CI check status.
          </p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-12">
          {STEPS.map((s) => (
            <div key={s.num} className="flex flex-col gap-4 rounded-[10px] border border-hairline bg-surface-2 p-6 lg:col-span-3">
              <span className="font-mono text-[13px] text-text-dim">{s.num}</span>
              <div className="flex min-h-[64px] items-center">{s.frag}</div>
              <div>
                <h3 className="text-[15px] font-medium text-text-primary">
                  {s.title}
                </h3>
                <p className="mt-1.5 text-[13px] leading-relaxed text-text-secondary">
                  {s.desc}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
