"use client";

import { useState, useEffect, type ReactNode } from "react";

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

  useEffect(() => {
    if (activeIdx === displayedIdx) return;
    setTransitioning(true);
    const timer = setTimeout(() => {
      setDisplayedIdx(activeIdx);
      setTransitioning(false);
    }, 300);
    return () => clearTimeout(timer);
  }, [activeIdx, displayedIdx]);

  return (
    <div className="relative" style={{ minHeight: 280 }}>
      {/* Outgoing scene */}
      {transitioning && displayedIdx !== activeIdx && (
        <div
          className="scene-layer absolute inset-0"
          style={{ opacity: 0, zIndex: 0 }}
        >
          {children(displayedIdx, false)}
        </div>
      )}

      {/* Current/incoming scene */}
      <div
        className="scene-layer"
        style={{
          opacity: 1,
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
