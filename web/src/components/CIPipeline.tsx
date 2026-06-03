"use client";

import { useRef, useState } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
import { StatusDot } from "./ui/primitives";
import type { DeployStatus } from "./ui/primitives";
import { useInView } from "@/hooks/useInView";

type Phase = "queued" | "running" | "passed";

const CHECKS = [
  { name: "Lint", dur: "18s" },
  { name: "Typecheck", dur: "24s" },
  { name: "Test", dur: "42s" },
  { name: "Build", dur: "1m 02s" },
  { name: "Deploy preview", dur: "12s" },
];

const QUEUED: Phase[] = CHECKS.map(() => "queued");
const ALL_PASSED: Phase[] = CHECKS.map(() => "passed");

// running-start / passed time per check (seconds) — each begins as the prior passes
const RUN = [0.2, 1.0, 1.5, 2.1, 3.3];
const PASS = [1.0, 1.5, 2.1, 3.3, 4.3];
const END = 4.3;

const DOT: Record<Phase, DeployStatus> = {
  queued: "queued",
  running: "building",
  passed: "ready",
};

export function CIPipeline({ active: activeProp }: { active?: boolean } = {}) {
  const { ref: inViewRef, inView } = useInView<HTMLDivElement>(0.35);
  // When `active` is supplied (e.g. inside the feature showcase) it drives the
  // animation; otherwise fall back to the section's own in-view detection.
  const active = activeProp ?? inView;
  const [phases, setPhases] = useState<Phase[]>(QUEUED);
  const panelRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      if (!active) {
        setPhases(QUEUED);
        if (progressRef.current) gsap.set(progressRef.current, { width: "0%" });
        return;
      }

      const mm = gsap.matchMedia();

      mm.add("(prefers-reduced-motion: no-preference)", () => {
        const setPhase = (i: number, p: Phase) =>
          setPhases((prev) => {
            const next = prev.slice();
            next[i] = p;
            return next;
          });

        const tl = gsap.timeline({ repeat: -1, repeatDelay: 1.6 });
        tl.call(() => setPhases(QUEUED), [], 0);
        if (progressRef.current) {
          gsap.set(progressRef.current, { width: "0%" });
          tl.to(
            progressRef.current,
            { width: "100%", duration: END, ease: "none" },
            0
          );
        }
        CHECKS.forEach((_, i) => {
          tl.call(() => setPhase(i, "running"), [], RUN[i]);
          tl.call(() => setPhase(i, "passed"), [], PASS[i]);
        });

        return () => setPhases(QUEUED);
      });

      mm.add("(prefers-reduced-motion: reduce)", () => {
        setPhases(ALL_PASSED);
        if (progressRef.current)
          gsap.set(progressRef.current, { width: "100%" });
        return () => setPhases(QUEUED);
      });
    },
    { dependencies: [active], revertOnUpdate: true, scope: panelRef }
  );

  return (
    <div ref={inViewRef} className="w-full max-w-[640px]">
      <div
        ref={panelRef}
        className="overflow-hidden rounded-[10px] border border-hairline bg-surface-2"
      >
        {/* pipeline progress bar */}
        <div className="h-[2px] w-full bg-hairline">
          <div
            ref={progressRef}
            className="h-full bg-status-ready"
            style={{ width: "0%" }}
          />
        </div>

        {/* caption bar */}
        <div className="flex items-center justify-between px-4 py-3">
          <span className="font-mono text-[11px] text-text-dim">
            github-actions · web-app · main
          </span>
          <span className="rounded-[4px] border border-hairline px-1.5 py-0.5 font-mono text-[10px] text-text-secondary">
            CI
          </span>
        </div>
        <div className="h-px w-full bg-hairline" />

        {/* check rows */}
        {CHECKS.map((c, i) => {
          const p = phases[i];
          return (
            <div key={c.name}>
              <div className="flex items-center justify-between px-4 py-3">
                <span className="flex items-center gap-2.5">
                  <StatusDot status={DOT[p]} pulse={p === "running"} />
                  <span className="text-[13px] font-medium text-text-primary">
                    {c.name}
                  </span>
                </span>
                <span
                  className={`font-mono text-[11px] ${
                    p === "running" ? "text-status-building" : "text-text-dim"
                  }`}
                >
                  {p === "running"
                    ? "Running"
                    : p === "passed"
                      ? c.dur
                      : "Queued"}
                </span>
              </div>
              {i < CHECKS.length - 1 && (
                <div className="h-px w-full bg-hairline" />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
