"use client";

import { useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
import { DeploymentRow } from "../MockupParts";
import type { ActionButtonId } from "../MockupParts";
import { deployments } from "../mockData";

interface QuickActionsState {
  expandedRow: string | null;
  highlightedButton: ActionButtonId | null;
}

const initialState: QuickActionsState = {
  expandedRow: null,
  highlightedButton: null,
};

export function QuickActionsScene({ active }: { active: boolean }) {
  const timeline = useMemo<TimelineStep<QuickActionsState>[]>(
    () => [
      {
        at: 800,
        apply: () => ({ expandedRow: "dpl_1", highlightedButton: null }),
      },
      {
        at: 1600,
        apply: (prev) => ({ ...prev, highlightedButton: "copy" }),
      },
      {
        at: 2400,
        apply: (prev) => ({ ...prev, highlightedButton: "browser" }),
      },
      {
        at: 3200,
        apply: (prev) => ({ ...prev, highlightedButton: "vercel" }),
      },
      {
        at: 4000,
        apply: (prev) => ({ ...prev, highlightedButton: "redeploy" }),
      },
      {
        at: 5200,
        apply: () => ({ expandedRow: null, highlightedButton: null }),
      },
    ],
    []
  );

  const state = useSceneTimeline(initialState, timeline, active);

  return (
    <div className="max-h-[280px] overflow-y-auto">
      {deployments.map((d) => (
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
