"use client";

import { useState, useRef, useCallback, useEffect } from "react";

type Phase = "idle" | "building" | "complete";

const BUILDING_DURATION = 1500; // ms

export function useDeployAnimation() {
  const [phase, setPhase] = useState<Phase>("idle");
  const [progress, setProgress] = useState(0);

  const rafRef = useRef<number>(0);
  const buildTimerRef = useRef<ReturnType<typeof setTimeout>>(undefined);
  const startTimeRef = useRef(0);

  const prefersReducedMotion =
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const cleanup = useCallback(() => {
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    if (buildTimerRef.current) clearTimeout(buildTimerRef.current);
  }, []);

  useEffect(() => cleanup, [cleanup]);

  const reset = useCallback(() => {
    cleanup();
    setPhase("idle");
    setProgress(0);
  }, [cleanup]);

  const deploy = useCallback(() => {
    if (phase !== "idle") return;

    cleanup();
    setPhase("building");
    setProgress(0);

    if (prefersReducedMotion) {
      setProgress(1);
      buildTimerRef.current = setTimeout(() => {
        setPhase("complete");
      }, 100);
      return;
    }

    // rAF loop for smooth progress
    startTimeRef.current = performance.now();

    const tick = (now: number) => {
      const elapsed = now - startTimeRef.current;
      const t = Math.min(elapsed / BUILDING_DURATION, 1);
      setProgress(t);

      if (t < 1) {
        rafRef.current = requestAnimationFrame(tick);
      }
    };

    rafRef.current = requestAnimationFrame(tick);

    // building → complete (stays complete until reset)
    buildTimerRef.current = setTimeout(() => {
      setPhase("complete");
    }, BUILDING_DURATION);
  }, [phase, cleanup, prefersReducedMotion]);

  return { phase, progress, deploy, reset } as const;
}
