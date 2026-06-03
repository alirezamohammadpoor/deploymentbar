"use client";

import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
import { SectionLabel } from "./ui/primitives";
import { usePillCycle } from "@/hooks/usePillCycle";
import { useInView } from "@/hooks/useInView";
import { MonitoringPanel } from "./MonitoringPanel";
import { QuickActionsPanel } from "./QuickActionsPanel";
import { CIPipeline } from "./CIPipeline";

const FEATURES = [
  {
    label: "Monitoring",
    lines: ["Every deployment,", "in one place."],
    body: "Every project and environment in one live list — filtered, sorted, and updated the moment anything changes.",
  },
  {
    label: "Quick actions",
    lines: ["One click, done.", "From the menu bar."],
    body: "Copy the URL, open in a browser, jump to Vercel or the pull request, or redeploy — without leaving the popover.",
  },
  {
    label: "CI status",
    lines: ["See every check,", "before you merge."],
    body: "Every GitHub Actions run, inline — build, lint, test, and deploy status the moment each one finishes.",
  },
];

const DURATIONS = [10000, 5500, 6500];

export function FeatureShowcase() {
  const { ref: inViewRef, inView } = useInView<HTMLElement>(0.25);
  const { activeIdx, progressKey, handlePillClick } = usePillCycle(
    3,
    { paused: !inView },
    DURATIONS,
  );
  const progressRef = useRef<HTMLDivElement>(null);

  // Auto-advance progress bar under the active title.
  useGSAP(
    () => {
      if (!progressRef.current) return;
      const mm = gsap.matchMedia();
      mm.add("(prefers-reduced-motion: no-preference)", () => {
        if (!inView) {
          gsap.set(progressRef.current, { scaleX: 0 });
          return;
        }
        gsap.fromTo(
          progressRef.current,
          { scaleX: 0 },
          {
            scaleX: 1,
            transformOrigin: "left",
            duration: DURATIONS[activeIdx] / 1000,
            ease: "none",
          },
        );
      });
      mm.add("(prefers-reduced-motion: reduce)", () => {
        gsap.set(progressRef.current, { scaleX: 1, transformOrigin: "left" });
      });
    },
    { dependencies: [progressKey, activeIdx, inView], scope: inViewRef, revertOnUpdate: true },
  );

  const renderPanel = () => {
    if (activeIdx === 0) return <MonitoringPanel active={inView} />;
    if (activeIdx === 1) return <QuickActionsPanel active={inView} />;
    return <CIPipeline active={inView} />;
  };

  return (
    <section id="features" ref={inViewRef} className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6 py-[88px]">
        <SectionLabel label="Features" />
        <div className="mt-10 grid grid-cols-1 gap-12 md:grid-cols-12 md:items-center md:gap-6">
          {/* left rail — clickable, auto-advancing feature titles */}
          <div className="md:col-span-5">
            <ul className="space-y-7">
              {FEATURES.map((f, i) => {
                const on = i === activeIdx;
                return (
                  <li key={f.label}>
                    <button
                      type="button"
                      onClick={() => handlePillClick(i)}
                      className="block w-full cursor-pointer text-left"
                    >
                      <h3
                        className={`text-[1.5rem] font-medium leading-[1.12] tracking-[-0.02em] transition-opacity duration-300 sm:text-[1.875rem] ${
                          on ? "opacity-100" : "opacity-35 hover:opacity-60"
                        }`}
                      >
                        <span className="block text-text-primary">
                          {f.lines[0]}
                        </span>
                        <span className="block text-text-secondary">
                          {f.lines[1]}
                        </span>
                      </h3>
                      {on && (
                        <>
                          <p className="mt-3 max-w-sm text-[14px] leading-relaxed text-text-secondary">
                            {f.body}
                          </p>
                          <div className="mt-4 h-px w-full max-w-sm overflow-hidden bg-hairline">
                            <div
                              ref={progressRef}
                              className="h-full w-full origin-left bg-text-secondary"
                              style={{ transform: "scaleX(0)" }}
                            />
                          </div>
                        </>
                      )}
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>

          {/* right — the active feature's live panel */}
          <div className="flex w-full justify-center md:col-start-7 md:col-span-6 md:min-h-[440px]">
            <div
              key={activeIdx}
              className="coded-hero-list-fade flex w-full max-w-[460px] justify-center"
            >
              {renderPanel()}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
