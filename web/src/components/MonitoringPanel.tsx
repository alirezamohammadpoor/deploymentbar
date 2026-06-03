"use client";

import { useState, useCallback, useEffect } from "react";
import { ScenePanel } from "./ScenePanel";
import { FilterScene } from "./CodedHero/scenes/FilterScene";
import type { FilterTab } from "./CodedHero/mockData";

/** The animated monitoring popover (FilterScene), gated by `active`. */
export function MonitoringPanel({ active }: { active: boolean }) {
  const [tab, setTab] = useState<FilterTab>("All");
  const [project, setProject] = useState<string | null>(null);
  const [cycle, setCycle] = useState(0);

  useEffect(() => {
    if (!active) return;
    const reduced =
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) return;
    const id = setInterval(() => setCycle((c) => c + 1), 10000);
    return () => clearInterval(id);
  }, [active]);

  const onTab = useCallback((t: FilterTab) => setTab(t), []);
  const onProject = useCallback((p: string | null) => setProject(p), []);

  return (
    <ScenePanel activeTab={tab} activeProject={project}>
      <FilterScene
        key={cycle}
        active={active}
        onTabChange={onTab}
        onProjectChange={onProject}
      />
    </ScenePanel>
  );
}
