import { HeroComposite } from "./CodedHero/HeroComposite";
import { Pill, SectionLabel, StatusDot } from "./ui/primitives";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/links";

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-background">
      {/* Calm upper void — content anchored to the shared left edge */}
      <div className="mx-auto max-w-[1200px] px-6 pt-32 md:pt-40">
        <SectionLabel label="Overview" />

        {/* Display headline — two lines, tight tracking, emphasis by tonal drop */}
        <h1 className="mt-8 text-display font-medium leading-[1.05] tracking-display">
          <span className="block text-text-primary">All your deployments,</span>
          <span className="block text-text-secondary">one glance away.</span>
        </h1>

        {/* Subhead (left) + inline status annotation (right edge) */}
        <div className="mt-7 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <p className="max-w-md text-[15px] leading-relaxed text-text-secondary">
            Monitor builds without switching tabs or breaking focus. Know the
            moment a deployment succeeds or fails.
          </p>
          <div className="flex shrink-0 items-center gap-2">
            <StatusDot status="ready" size={7} />
            <span className="font-mono text-micro text-text-dim">
              Live · CI passed
            </span>
          </div>
        </div>

        {/* CTA — primary light-fill pill + equal-size secondary hairline pill */}
        <div className="mt-9 flex flex-wrap items-center gap-3">
          <Pill href={DOWNLOAD_URL}>Download for macOS</Pill>
          <Pill variant="secondary" href={GITHUB_URL}>
            View on GitHub →
          </Pill>
        </div>

        <p className="mt-4 font-mono text-micro text-text-dim">
          Free public beta · macOS 14+
        </p>
      </div>

      {/* Product embed — enlarged, value-step + hairline, cropped to bleed off the bottom */}
      <div className="mx-auto mt-16 max-w-5xl px-6 md:mt-20">
        <div className="h-[420px] overflow-hidden md:h-[540px]">
          <HeroComposite />
        </div>
      </div>
    </section>
  );
}
