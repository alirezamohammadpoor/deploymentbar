"use client";

import { useState, useEffect, useRef, useCallback } from "react";

export interface TimelineStep<T> {
  at: number; // ms from scene start
  apply: (prev: T) => T;
}

interface UseSceneTimelineOptions {
  loop?: boolean;
  duration?: number; // total scene duration in ms (needed for loop)
}

export function useSceneTimeline<T>(
  initialState: T,
  timeline: TimelineStep<T>[],
  active: boolean,
  options: UseSceneTimelineOptions = {}
) {
  const [state, setState] = useState<T>(initialState);
  const stateRef = useRef<T>(initialState);
  const timersRef = useRef<ReturnType<typeof setTimeout>[]>([]);
  const loopTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const reducedMotionRef = useRef(false);

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

  const cleanup = useCallback(() => {
    timersRef.current.forEach(clearTimeout);
    timersRef.current = [];
    if (loopTimerRef.current) {
      clearTimeout(loopTimerRef.current);
      loopTimerRef.current = null;
    }
  }, []);

  const runTimeline = useCallback(() => {
    cleanup();
    stateRef.current = initialState;
    setState(initialState);

    if (reducedMotionRef.current) {
      // Apply all steps instantly for reduced motion
      let s = initialState;
      for (const step of timeline) {
        s = step.apply(s);
      }
      stateRef.current = s;
      setState(s);
      return;
    }

    const sorted = [...timeline].sort((a, b) => a.at - b.at);
    for (const step of sorted) {
      const timer = setTimeout(() => {
        // Call apply outside setState updater so side effects
        // don't run during React's render phase
        const next = step.apply(stateRef.current);
        stateRef.current = next;
        setState(next);
      }, step.at);
      timersRef.current.push(timer);
    }

    if (options.loop && options.duration) {
      loopTimerRef.current = setTimeout(() => {
        runTimeline();
      }, options.duration);
    }
  }, [initialState, timeline, options.loop, options.duration, cleanup]);

  useEffect(() => {
    if (active) {
      runTimeline();
    } else {
      cleanup();
      stateRef.current = initialState;
      setState(initialState);
    }
    return cleanup;
    // Only re-run when `active` changes. Other deps (runTimeline, cleanup,
    // initialState) are intentionally excluded to avoid restarting all timers
    // on every parent re-render — the timeline should only reset on scene switch.
  }, [active]); // eslint-disable-line react-hooks/exhaustive-deps

  return state;
}
