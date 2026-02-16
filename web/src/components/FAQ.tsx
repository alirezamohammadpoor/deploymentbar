"use client";

import { useState } from "react";
import { CaretDown } from "@phosphor-icons/react/dist/icons/CaretDown";

const faqs = [
  {
    question: "How much time will this save me?",
    answer:
      "Absolutely. Instead of switching to your browser, finding the Vercel tab, and navigating to your project, DeployBar shows every deployment status right in your menu bar. Most developers save 10+ context switches per day.",
  },
  {
    question: "Is it secure?",
    answer:
      "Yes. DeployBar uses Vercel's official OAuth2 with PKCE — the same security standard used by Vercel's own integrations. Your credentials are never stored in plain text.",
  },
  {
    question: "How long does setup take?",
    answer:
      "Under a minute. Install the app, click \"Sign in with Vercel\", authorize, and you're done. Your deployments appear immediately.",
  },
  {
    question: "What happens after the beta?",
    answer:
      "We're keeping DeployBar free during the beta period. When we introduce pricing, early waitlist members will get a generous discount.",
  },
  {
    question: "What if I need help?",
    answer:
      "Reach out on GitHub Issues or Twitter. We're a small team and we respond fast.",
  },
];

export function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  function toggle(index: number) {
    setOpenIndex(openIndex === index ? null : index);
  }

  return (
    <section className="mx-auto max-w-3xl px-6 py-24">
      <h2 className="mb-12 text-center text-3xl font-medium text-text-primary md:text-[32px]">
        Frequently Asked Questions
      </h2>

      <div className="divide-y divide-card-border">
        {faqs.map((faq, i) => {
          const isOpen = openIndex === i;
          return (
            <div key={faq.question}>
              <button
                type="button"
                onClick={() => toggle(i)}
                className="flex w-full items-center justify-between py-5 text-left cursor-pointer"
              >
                <span className="text-base font-medium text-text-primary pr-4">
                  {faq.question}
                </span>
                <CaretDown
                  size={18}
                  className={`shrink-0 text-text-secondary transition-transform duration-200 ${
                    isOpen ? "rotate-180" : ""
                  }`}
                />
              </button>
              <div
                className={`grid transition-[grid-template-rows] duration-200 ${
                  isOpen ? "grid-rows-[1fr]" : "grid-rows-[0fr]"
                }`}
              >
                <div className="overflow-hidden">
                  <p className="pb-5 text-base leading-relaxed text-text-secondary">
                    {faq.answer}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
