"use client";

import { useEffect, useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
import { useDeployAnimation } from "../../../hooks/useDeployAnimation";
import { DeploymentRow } from "../MockupParts";
import { deployments, type MockDeployment } from "../mockData";

interface MonitoringState {
  buildingStatus: "building" | "ready";
}

const initialState: MonitoringState = {
  buildingStatus: "building",
};

export function MonitoringScene({
  active,
  onNotification,
  onPhaseChange,
}: {
  active: boolean;
  onNotification: (visible: boolean, exiting: boolean) => void;
  onPhaseChange: (phase: string, progress: number) => void;
}) {
  const { phase, progress, deploy } = useDeployAnimation();

  const timeline = useMemo<TimelineStep<MonitoringState>[]>(
    () => [
      {
        at: 1500,
        apply: (prev) => ({ ...prev, buildingStatus: "ready" as const }),
      },
    ],
    []
  );

  const state = useSceneTimeline(initialState, timeline, active);

  // Drive the deploy animation and notifications via a side-effect timeline
  useSceneTimeline(
    null,
    useMemo<TimelineStep<null>[]>(
      () => [
        {
          at: 10,
          apply: () => {
            deploy();
            return null;
          },
        },
        {
          at: 1800,
          apply: () => {
            onNotification(true, false);
            return null;
          },
        },
        {
          at: 3800,
          apply: () => {
            onNotification(true, true);
            return null;
          },
        },
        {
          at: 4100,
          apply: () => {
            onNotification(false, false);
            return null;
          },
        },
      ],
      [deploy, onNotification]
    ),
    active
  );

  // Forward phase/progress to parent
  useEffect(() => {
    if (active) {
      onPhaseChange(phase, progress);
    }
  }, [phase, progress, active, onPhaseChange]);

  const sceneDeployments: MockDeployment[] = deployments.map((d) => {
    if (d.id === "dpl_2") {
      return { ...d, status: state.buildingStatus };
    }
    return d;
  });

  return (
    <div className="max-h-[280px] overflow-y-auto">
      {sceneDeployments.map((d) => (
        <DeploymentRow key={d.id} deployment={d} />
      ))}
    </div>
  );
}
