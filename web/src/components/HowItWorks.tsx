const steps = [
  {
    number: "01",
    title: "Connect",
    description:
      "Seamlessly sign in with your Vercel account. One click, no API tokens needed.",
  },
  {
    number: "02",
    title: "Configure",
    description:
      "Choose exactly which projects to monitor, or keep an eye on everything at once.",
  },
  {
    number: "03",
    title: "Deploy",
    description:
      "Your deployments are always one glance away. No more hunting for the right browser tab.",
  },
];

export function HowItWorks() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-24">
      <h2 className="mb-12 text-center text-3xl font-medium text-text-primary md:text-[32px]">
        Up and running in{" "}
        <span className="text-accent-blue">three steps</span>
      </h2>

      <div className="grid gap-8 md:grid-cols-3">
        {steps.map((step) => (
          <div key={step.number} className="flex flex-col items-center text-center">
            {/* Image placeholder */}
            <div className="mb-6 flex aspect-video w-full items-center justify-center rounded-xl border border-dashed border-card-border bg-card-bg">
              <span className="text-sm text-text-secondary/50">Coming soon</span>
            </div>

            {/* Number badge */}
            <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-full bg-white">
              <span className="text-sm font-semibold text-black">
                {step.number}
              </span>
            </div>

            <h3 className="mb-2 text-xl font-medium text-text-primary">
              {step.title}
            </h3>
            <p className="text-base text-text-secondary">{step.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
