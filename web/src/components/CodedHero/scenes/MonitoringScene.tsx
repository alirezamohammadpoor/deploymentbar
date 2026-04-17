"use client";

import { useState, useRef, useCallback } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
import { DeploymentRow } from "../MockupParts";
import { deployments, type MockDeployment, type CIStatus } from "../mockData";

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
}: {
  active: boolean;
  onNotification: (visible: boolean, exiting: boolean) => void;
  onPhaseChange: (phase: string, progress: number) => void;
}) {
  const [state, setState] = useState<MonitoringState>(initialState);
  const containerRef = useRef<HTMLDivElement>(null);

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

        // Deploy progress (0→1 over 2s) — triangle pulses orange while building
        tl.to(
          proxy,
          {
            progress: 1,
            duration: 2.0,
            ease: "none",
            onStart: () => stableOnPhaseChange("building", 0),
            onUpdate: () => stableOnPhaseChange("building", proxy.progress),
            onComplete: () => stableOnPhaseChange("complete", 1),
          },
          0.01
        );

        // Building → Ready (row flips to green + CI passed)
        tl.call(
          () =>
            setState({
              buildingStatus: "ready",
              buildingCiStatus: "passed",
            }),
          [],
          2.0
        );

        // Notification enter → exit
        tl.call(() => stableOnNotification(true, false), [], 2.4);
        tl.call(() => stableOnNotification(true, true), [], 5.4);
        tl.call(() => stableOnNotification(false, false), [], 5.7);

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
      dependencies: [active, stableOnNotification, stableOnPhaseChange],
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
