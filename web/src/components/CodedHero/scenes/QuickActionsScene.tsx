"use client";

import { useState, useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
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
  const [state, setState] = useState<QuickActionsState>(initialState);
  const containerRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      if (!active) {
        setState(initialState);
        return;
      }

      const mm = gsap.matchMedia();

      mm.add("(prefers-reduced-motion: no-preference)", () => {
        const tl = gsap.timeline();

        tl.call(() => setState({ expandedRow: "dpl_1", highlightedButton: null }), [], 0.8);
        tl.call(() => setState((prev) => ({ ...prev, highlightedButton: "copy" })), [], 1.6);
        tl.call(() => setState((prev) => ({ ...prev, highlightedButton: "browser" })), [], 2.2);
        tl.call(() => setState((prev) => ({ ...prev, highlightedButton: "vercel" })), [], 2.8);
        tl.call(() => setState((prev) => ({ ...prev, highlightedButton: "pr" })), [], 3.4);
        tl.call(() => setState((prev) => ({ ...prev, highlightedButton: "redeploy" })), [], 4.0);
        tl.call(() => setState({ expandedRow: null, highlightedButton: null }), [], 5.0);

        return () => setState(initialState);
      });

      mm.add("(prefers-reduced-motion: reduce)", () => {
        setState({ expandedRow: "dpl_1", highlightedButton: "copy" });
        return () => setState(initialState);
      });
    },
    { dependencies: [active], revertOnUpdate: true, scope: containerRef }
  );

  return (
    <div ref={containerRef} className="max-h-[280px] overflow-y-auto">
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
