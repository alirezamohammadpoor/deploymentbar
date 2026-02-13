"use client";

import { useState, useEffect, useRef, useCallback } from "react";

const CYCLE_INTERVAL = 6000;
const INACTIVITY_DELAY = 10000;

interface UsePillCycleOptions {
  interval?: number;
  inactivityDelay?: number;
}

export function usePillCycle(count: number, options: UsePillCycleOptions = {}) {
  const interval = options.interval ?? CYCLE_INTERVAL;
  const inactivityDelay = options.inactivityDelay ?? INACTIVITY_DELAY;

  const [activeIdx, setActiveIdx] = useState(0);
  const [progressKey, setProgressKey] = useState(0);

  const autoCycleRef = useRef(true);
  const cycleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const inactivityTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const reducedMotionRef = useRef(false);
  const activeIdxRef = useRef(activeIdx);
  activeIdxRef.current = activeIdx;

  useEffect(() => {
    if (typeof window === "undefined") return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    reducedMotionRef.current = mq.matches;
    const handler = (e: MediaQueryListEvent) => {
      reducedMotionRef.current = e.matches;
    };
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  const advance = useCallback(
    (idx: number) => {
      setActiveIdx(idx);
      setProgressKey((k) => k + 1);
    },
    []
  );

  // Auto-cycle
  useEffect(() => {
    if (reducedMotionRef.current) return;

    const clearCycle = () => {
      if (cycleTimerRef.current) {
        clearTimeout(cycleTimerRef.current);
        cycleTimerRef.current = null;
      }
    };

    const startCycle = () => {
      clearCycle();
      if (!autoCycleRef.current) return;
      cycleTimerRef.current = setTimeout(() => {
        const next = (activeIdxRef.current + 1) % count;
        advance(next);
      }, interval);
    };

    startCycle();
    return clearCycle;
  }, [activeIdx, count, interval, advance]);

  const handlePillClick = useCallback(
    (idx: number) => {
      autoCycleRef.current = false;
      if (cycleTimerRef.current) {
        clearTimeout(cycleTimerRef.current);
        cycleTimerRef.current = null;
      }

      if (idx !== activeIdx) {
        advance(idx);
      } else {
        setProgressKey((k) => k + 1);
      }

      if (inactivityTimerRef.current) {
        clearTimeout(inactivityTimerRef.current);
      }
      inactivityTimerRef.current = setTimeout(() => {
        autoCycleRef.current = true;
        const next = (idx + 1) % count;
        advance(next);
      }, inactivityDelay);
    },
    [activeIdx, count, inactivityDelay, advance]
  );

  // Cleanup
  useEffect(() => {
    return () => {
      if (cycleTimerRef.current) clearTimeout(cycleTimerRef.current);
      if (inactivityTimerRef.current) clearTimeout(inactivityTimerRef.current);
    };
  }, []);

  return { activeIdx, progressKey, handlePillClick };
}
