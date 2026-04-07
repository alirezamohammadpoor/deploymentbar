"use client";

import { useState, useRef, useCallback } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
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
  const [state, setState] = useState<MonitoringState>(initialState);
  const containerRef = useRef<HTMLDivElement>(null);

  const stableOnZoom = useCallback(onZoom, [onZoom]);
  const stableOnNotification = useCallback(onNotification, [onNotification]);
  const stableOnPhaseChange = useCallback(onPhaseChange, [onPhaseChange]);

  useGSAP(
    () => {
      if (!active) {
        setState(initialState);
        stableOnPhaseChange("idle", 0);
        return;
      }

      const mm = gsap.matchMedia();

      mm.add("(prefers-reduced-motion: no-preference)", () => {
        const proxy = { progress: 0 };
        const tl = gsap.timeline();

        // Deploy progress (0→1 over 1.5s)
        tl.to(
          proxy,
          {
            progress: 1,
            duration: 1.5,
            ease: "none",
            onStart: () => stableOnPhaseChange("building", 0),
            onUpdate: () => stableOnPhaseChange("building", proxy.progress),
            onComplete: () => stableOnPhaseChange("complete", 1),
          },
          0.01
        );

        // Zoom in
        tl.call(() => stableOnZoom("zoomed"), [], 0.6);

        // Building → Ready
        tl.call(
          () =>
            setState({
              buildingStatus: "ready",
              buildingCiStatus: "passed",
            }),
          [],
          1.5
        );

        // Zoom out sequence
        tl.call(() => stableOnZoom("zooming-out"), [], 2.0);
        tl.call(() => stableOnZoom("normal"), [], 3.2);

        // Notification enter → exit
        tl.call(() => stableOnNotification(true, false), [], 3.6);
        tl.call(() => stableOnNotification(true, true), [], 5.6);
        tl.call(() => stableOnNotification(false, false), [], 5.9);

        return () => {
          setState(initialState);
          stableOnPhaseChange("idle", 0);
        };
      });

      mm.add("(prefers-reduced-motion: reduce)", () => {
        setState({ buildingStatus: "ready", buildingCiStatus: "passed" });
        stableOnPhaseChange("complete", 1);
        return () => {
          setState(initialState);
          stableOnPhaseChange("idle", 0);
        };
      });
    },
    {
      dependencies: [active, stableOnZoom, stableOnNotification, stableOnPhaseChange],
      revertOnUpdate: true,
      scope: containerRef,
    }
  );

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
    <div ref={containerRef} className="max-h-[280px] overflow-y-auto">
      {sceneDeployments.map((d) => (
        <DeploymentRow key={d.id} deployment={d} />
      ))}
    </div>
  );
}
