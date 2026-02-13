"use client";

import { useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
import { DeploymentRow } from "../MockupParts";
import type { ActionButtonId } from "../MockupParts";
import { deployments } from "../mockData";

interface BrowserState {
  expandedRow: string | null;
  highlightedButton: ActionButtonId | null;
  tooltip: string | null;
}

const initialState: BrowserState = {
  expandedRow: null,
  highlightedButton: null,
  tooltip: null,
};

export function BrowserScene({ active }: { active: boolean }) {
  const timeline = useMemo<TimelineStep<BrowserState>[]>(
    () => [
      {
        at: 600,
        apply: () => ({
          expandedRow: "dpl_1",
          highlightedButton: null,
          tooltip: null,
        }),
      },
      {
        at: 1200,
        apply: (prev) => ({ ...prev, highlightedButton: "browser" }),
      },
      {
        at: 2200,
        apply: (prev) => ({
          ...prev,
          highlightedButton: "browser",
          tooltip: "Opening web-app.vercel.app...",
        }),
      },
      {
        at: 3200,
        apply: (prev) => ({
          ...prev,
          highlightedButton: null,
          tooltip: null,
        }),
      },
      {
        at: 4200,
        apply: () => ({
          expandedRow: null,
          highlightedButton: null,
          tooltip: null,
        }),
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
          tooltip={d.id === state.expandedRow ? state.tooltip : null}
        />
      ))}
    </div>
  );
}
