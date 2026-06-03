import { Pill } from "./ui/primitives";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/links";

export function FinalCTA() {
  return (
    <section id="download" className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6 pt-[144px] pb-[96px]">
        <div className="flex flex-col items-center text-center">
          <h2 className="text-[2.5rem] font-medium leading-[1.1] tracking-[-0.03em] sm:text-[3.25rem]">
            <span className="block text-text-primary">All your deployments.</span>
            <span className="block text-text-secondary">One glance away.</span>
          </h2>
          <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
            <Pill href={DOWNLOAD_URL}>Download for macOS</Pill>
            <Pill variant="secondary" href={GITHUB_URL}>
              View on GitHub →
            </Pill>
          </div>
          <p className="mt-5 font-mono text-[12px] text-text-dim">
            Free public beta · macOS 14+
          </p>
        </div>
      </div>
    </section>
  );
}
