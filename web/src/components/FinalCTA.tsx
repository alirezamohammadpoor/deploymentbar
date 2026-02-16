import { DownloadSimple } from "@phosphor-icons/react/dist/ssr/DownloadSimple";

export function FinalCTA() {
  return (
    <section id="download" className="mx-auto max-w-6xl px-6 py-24">
      <div className="rounded-xl border border-card-border bg-card-bg p-10 text-center md:p-16">
        <h2 className="text-3xl font-medium text-text-primary md:text-[32px]">
          Stop refreshing Vercel.
        </h2>

        <p className="mx-auto mt-4 max-w-md text-lg text-text-secondary">
          Your deployments, always one glance away.
        </p>

        <div className="mt-8 flex flex-col items-center gap-3">
          <a
            href="#download"
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-accent-blue px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#005bd4]"
          >
            <DownloadSimple size={18} weight="bold" />
            Download for macOS
          </a>
          <p className="text-xs text-text-secondary/50">
            Free public beta &middot; macOS 14+
          </p>
        </div>
      </div>
    </section>
  );
}
