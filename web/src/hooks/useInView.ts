"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Returns a ref + whether that element is currently on screen.
 * Used to gate looping scene animations so they only run while visible
 * (and restart each time the section re-enters the viewport).
 */
export function useInView<T extends HTMLElement = HTMLDivElement>(
  threshold = 0.35
) {
  const ref = useRef<T>(null);
  const [inView, setInView] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return;
    const obs = new IntersectionObserver(
      ([entry]) => setInView(entry.isIntersecting),
      { threshold }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [threshold]);

  return { ref, inView };
}
