"use client";

import { useState, useEffect } from "react";
import { ScenePanel } from "./ScenePanel";
import { QuickActionsScene } from "./CodedHero/scenes/QuickActionsScene";

/** The animated quick-actions popover (QuickActionsScene), gated by `active`. */
export function QuickActionsPanel({ active }: { active: boolean }) {
  const [cycle, setCycle] = useState(0);

  useEffect(() => {
    if (!active) return;
    const reduced =
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) return;
    const id = setInterval(() => setCycle((c) => c + 1), 5500);
    return () => clearInterval(id);
  }, [active]);

  return (
    <ScenePanel activeTab="All" activeProject={null}>
      <QuickActionsScene key={cycle} active={active} />
    </ScenePanel>
  );
}
