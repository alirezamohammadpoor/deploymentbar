import { WaitlistForm } from "./WaitlistForm";

export function FinalCTA() {
  return (
    <section id="download" className="mx-auto max-w-6xl px-6 py-24">
      <div className="rounded-xl border border-card-border bg-card-bg p-10 text-center md:p-16">
        <h2 className="text-3xl font-medium text-text-primary md:text-[32px]">
          Stop refreshing Vercel.
          <br />
          <span className="text-accent-blue">
            Let DeployBar watch for you.
          </span>
        </h2>

        <p className="mx-auto mt-4 max-w-md text-lg text-text-secondary">
          Join developers shipping faster with less noise.
        </p>

        <div className="mt-8 flex flex-col items-center gap-4">
          <WaitlistForm id="cta-waitlist" />
          <a
            href="#"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors underline underline-offset-4"
          >
            Download for macOS
          </a>
        </div>
      </div>
    </section>
  );
}
