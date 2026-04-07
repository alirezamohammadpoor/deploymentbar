"use client";

import { useState, useRef, useCallback } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
import { DeploymentRow } from "../MockupParts";
import { filterDeployments, filterByProject, type FilterTab } from "../mockData";

interface FilterState {
  activeTab: FilterTab;
  activeProject: string | null;
}

const initialState: FilterState = {
  activeTab: "All",
  activeProject: null,
};

export function FilterScene({
  active,
  onTabChange,
  onProjectChange,
}: {
  active: boolean;
  onTabChange: (tab: FilterTab) => void;
  onProjectChange?: (project: string | null) => void;
}) {
  const [state, setState] = useState<FilterState>(initialState);
  const containerRef = useRef<HTMLDivElement>(null);

  const stableOnTabChange = useCallback(onTabChange, [onTabChange]);
  const stableOnProjectChange = useCallback(
    (p: string | null) => onProjectChange?.(p),
    [onProjectChange]
  );

  const applyFilter = useCallback(
    (tab: FilterTab, project: string | null) => {
      stableOnTabChange(tab);
      stableOnProjectChange(project);
      setState({ activeTab: tab, activeProject: project });
    },
    [stableOnTabChange, stableOnProjectChange]
  );

  useGSAP(
    () => {
      if (!active) {
        setState(initialState);
        return;
      }

      const mm = gsap.matchMedia();

      mm.add("(prefers-reduced-motion: no-preference)", () => {
        const tl = gsap.timeline();

        tl.call(() => applyFilter("All", null), [], 0);
        tl.call(() => applyFilter("All", "web-app"), [], 1.5);
        tl.call(() => applyFilter("All", "dashboard"), [], 3.5);
        tl.call(() => applyFilter("Production", null), [], 5.5);
        tl.call(() => applyFilter("Preview", null), [], 7.5);
        tl.call(() => applyFilter("All", null), [], 9.5);

        return () => setState(initialState);
      });

      mm.add("(prefers-reduced-motion: reduce)", () => {
        applyFilter("All", null);
        return () => setState(initialState);
      });
    },
    {
      dependencies: [active, applyFilter],
      revertOnUpdate: true,
      scope: containerRef,
    }
  );

  const filtered = filterByProject(
    filterDeployments(state.activeTab),
    state.activeProject
  );

  return (
    <div ref={containerRef} className="max-h-[280px] overflow-y-auto">
      <div
        key={`${state.activeTab}-${state.activeProject}`}
        className="coded-hero-list-fade"
      >
        {filtered.map((d) => (
          <DeploymentRow key={d.id} deployment={d} />
        ))}
      </div>
    </div>
  );
}
