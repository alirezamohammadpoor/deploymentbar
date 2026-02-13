"use client";

import { useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
import { DeploymentRow } from "../MockupParts";
import { filterDeployments, type FilterTab } from "../mockData";

interface FilterState {
  activeTab: FilterTab;
}

const initialState: FilterState = {
  activeTab: "All",
};

export function FilterScene({
  active,
  onTabChange,
}: {
  active: boolean;
  onTabChange: (tab: FilterTab) => void;
}) {
  const timeline = useMemo<TimelineStep<FilterState>[]>(
    () => [
      {
        at: 0,
        apply: () => {
          onTabChange("All");
          return { activeTab: "All" as FilterTab };
        },
      },
      {
        at: 1800,
        apply: () => {
          onTabChange("Production");
          return { activeTab: "Production" as FilterTab };
        },
      },
      {
        at: 3600,
        apply: () => {
          onTabChange("Preview");
          return { activeTab: "Preview" as FilterTab };
        },
      },
      {
        at: 5400,
        apply: () => {
          onTabChange("All");
          return { activeTab: "All" as FilterTab };
        },
      },
    ],
    [onTabChange]
  );

  const state = useSceneTimeline(initialState, timeline, active);
  const filtered = filterDeployments(state.activeTab);

  return (
    <div className="max-h-[280px] overflow-y-auto">
      <div key={state.activeTab} className="coded-hero-list-fade">
        {filtered.map((d) => (
          <DeploymentRow key={d.id} deployment={d} />
        ))}
      </div>
    </div>
  );
}
