"use client";

import { useEffect, useMemo } from "react";
import { useSceneTimeline, type TimelineStep } from "../../../hooks/useSceneTimeline";
import { useDeployAnimation } from "../../../hooks/useDeployAnimation";
import { DeploymentRow } from "../MockupParts";
import { deployments, type MockDeployment, type CIStatus, type ZoomPhase } from "../mockData";

interface MonitoringState {
  buildingStatus: "building" | "ready";
  buildingCiStatus: CIStatus;
}

const initialState: MonitoringState = {
  buildingStatus: "building",
  buildingCiStatus: "running",
};

export function MonitoringScene({
  active,
  onNotification,
  onPhaseChange,
  onZoom,
}: {
  active: boolean;
  onNotification: (visible: boolean, exiting: boolean) => void;
  onPhaseChange: (phase: string, progress: number) => void;
  onZoom: (phase: ZoomPhase) => void;
}) {
  const { phase, progress, deploy, reset } = useDeployAnimation();

  // Reset deploy animation when scene deactivates so it can re-trigger on re-entry
  useEffect(() => {
    if (!active) reset();
  }, [active, reset]);

  const timeline = useMemo<TimelineStep<MonitoringState>[]>(
    () => [
      {
        at: 1500,
        apply: () => ({
          buildingStatus: "ready" as const,
          buildingCiStatus: "passed" as CIStatus,
        }),
      },
    ],
    []
  );

  const state = useSceneTimeline(initialState, timeline, active);

  // Drive the deploy animation, zoom, and notifications via a side-effect timeline
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
          at: 600,
          apply: () => {
            onZoom("zoomed");
            return null;
          },
        },
        {
          at: 2000,
          apply: () => {
            onZoom("zooming-out");
            return null;
          },
        },
        {
          at: 3200,
          apply: () => {
            onZoom("normal");
            return null;
          },
        },
        {
          at: 3600,
          apply: () => {
            onNotification(true, false);
            return null;
          },
        },
        {
          at: 5600,
          apply: () => {
            onNotification(true, true);
            return null;
          },
        },
        {
          at: 5900,
          apply: () => {
            onNotification(false, false);
            return null;
          },
        },
      ],
      [deploy, onNotification, onZoom]
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
      return {
        ...d,
        status: state.buildingStatus,
        ciStatus: state.buildingCiStatus,
      };
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
