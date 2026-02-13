"use client";

import { useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
import { DeploymentRow } from "../MockupParts";
import type { ActionButtonId } from "../MockupParts";
import { filterDeployments } from "../mockData";

interface RollbackState {
  expandedRow: string | null;
  highlightedButton: ActionButtonId | null;
}

const initialState: RollbackState = {
  expandedRow: null,
  highlightedButton: null,
};

export function RollbackScene({ active }: { active: boolean }) {
  const timeline = useMemo<TimelineStep<RollbackState>[]>(
    () => [
      {
        at: 800,
        apply: () => ({ expandedRow: "dpl_1", highlightedButton: null }),
      },
      {
        at: 1500,
        apply: (prev) => ({ ...prev, highlightedButton: "rollback" }),
      },
      {
        at: 2500,
        apply: (prev) => ({ ...prev, highlightedButton: null }),
      },
      {
        at: 2800,
        apply: (prev) => ({ ...prev, highlightedButton: "rollback" }),
      },
      {
        at: 3500,
        apply: (prev) => ({ ...prev, highlightedButton: null }),
      },
      {
        at: 3800,
        apply: (prev) => ({ ...prev, highlightedButton: "rollback" }),
      },
      {
        at: 4800,
        apply: () => ({ expandedRow: null, highlightedButton: null }),
      },
    ],
    []
  );

  const state = useSceneTimeline(initialState, timeline, active);
  const productionDeployments = filterDeployments("Production");

  return (
    <div className="max-h-[280px] overflow-y-auto">
      {productionDeployments.map((d) => (
        <DeploymentRow
          key={d.id}
          deployment={d}
          expanded={d.id === state.expandedRow}
          highlightedButton={
            d.id === state.expandedRow ? state.highlightedButton : null
          }
        />
      ))}
    </div>
  );
}
