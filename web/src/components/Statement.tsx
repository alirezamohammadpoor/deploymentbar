import { SectionLabel } from "./ui/primitives";

export function Statement() {
  return (
    <section className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6 py-[88px]">
        <SectionLabel label="Why" />
        <h2 className="mt-8 max-w-3xl text-[2.5rem] font-medium leading-[1.1] tracking-[-0.03em] sm:text-[3.25rem]">
          <span className="block text-text-primary">Stop refreshing Vercel.</span>
          <span className="block text-text-secondary">
            Watch every deploy from your menu bar.
          </span>
        </h2>
      </div>
    </section>
  );
}
