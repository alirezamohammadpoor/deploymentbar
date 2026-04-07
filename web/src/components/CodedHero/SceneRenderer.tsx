"use client";

import { useState, useEffect, useRef, type ReactNode } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

interface SceneRendererProps {
  activeIdx: number;
  children: (sceneIdx: number, isActive: boolean) => ReactNode;
  sceneCount: number;
}

export function SceneRenderer({
  activeIdx,
  children,
  sceneCount,
}: SceneRendererProps) {
  const [displayedIdx, setDisplayedIdx] = useState(activeIdx);
  const [transitioning, setTransitioning] = useState(false);
  const outgoingRef = useRef<HTMLDivElement>(null);
  const incomingRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      if (activeIdx === displayedIdx) return;
      setTransitioning(true);

      const tl = gsap.timeline({
        onComplete: () => {
          setDisplayedIdx(activeIdx);
          setTransitioning(false);
        },
      });

      if (outgoingRef.current) {
        tl.to(outgoingRef.current, { autoAlpha: 0, duration: 0.3, ease: "power1.out" }, 0);
      }
      if (incomingRef.current) {
        tl.fromTo(
          incomingRef.current,
          { autoAlpha: 0 },
          { autoAlpha: 1, duration: 0.3, ease: "power1.out" },
          0
        );
      }
    },
    { dependencies: [activeIdx], scope: containerRef }
  );

  return (
    <div ref={containerRef} className="relative" style={{ minHeight: 280 }}>
      {/* Outgoing scene */}
      {transitioning && displayedIdx !== activeIdx && (
        <div
          ref={outgoingRef}
          className="absolute inset-0"
          style={{ zIndex: 0 }}
        >
          {children(displayedIdx, false)}
        </div>
      )}

      {/* Current/incoming scene */}
      <div
        ref={incomingRef}
        style={{
          zIndex: 1,
          position: transitioning ? "absolute" : "relative",
          inset: transitioning ? 0 : undefined,
        }}
      >
        {children(activeIdx, !transitioning)}
      </div>
    </div>
  );
}
