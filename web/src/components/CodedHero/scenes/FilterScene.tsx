"use client";

import { useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
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
  const timeline = useMemo<TimelineStep<FilterState>[]>(
    () => [
      {
        at: 0,
        apply: () => {
          onTabChange("All");
          onProjectChange?.("web-app");
          return { activeTab: "All" as FilterTab, activeProject: "web-app" };
        },
      },
      {
        at: 2000,
        apply: () => {
          onTabChange("All");
          onProjectChange?.(null);
          return { activeTab: "All" as FilterTab, activeProject: null };
        },
      },
      {
        at: 4000,
        apply: () => {
          onTabChange("Production");
          onProjectChange?.(null);
          return { activeTab: "Production" as FilterTab, activeProject: null };
        },
      },
      {
        at: 6000,
        apply: () => {
          onTabChange("Preview");
          onProjectChange?.(null);
          return { activeTab: "Preview" as FilterTab, activeProject: null };
        },
      },
      {
        at: 7500,
        apply: () => {
          onTabChange("All");
          onProjectChange?.(null);
          return { activeTab: "All" as FilterTab, activeProject: null };
        },
      },
    ],
    [onTabChange, onProjectChange]
  );

  const state = useSceneTimeline(initialState, timeline, active);
  const filtered = filterByProject(
    filterDeployments(state.activeTab),
    state.activeProject
  );

  return (
    <div className="max-h-[280px] overflow-y-auto">
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
