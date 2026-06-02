"use client";

import type { ReactNode } from "react";
import { PopoverHeader, FilterTabs } from "./CodedHero/MockupParts";
import type { FilterTab } from "./CodedHero/mockData";

/**
 * The product popover as a standalone marketing panel — the macOS-window
 * chrome of the hero stripped away, leaving the header + filter tabs + a
 * scene content area. Reused by the animated feature sections (Monitoring,
 * Quick Actions). Elevation = value step + hairline (no shadow).
 */
export function ScenePanel({
  activeTab,
  activeProject,
  children,
}: {
  activeTab: FilterTab;
  activeProject?: string | null;
  children: ReactNode;
}) {
  return (
    <div className="w-full max-w-[420px] overflow-hidden rounded-xl border border-card-border bg-card-bg">
      <PopoverHeader activeProject={activeProject} />
      <FilterTabs activeTab={activeTab} />
      <div className="relative" style={{ minHeight: 280 }}>
        {children}
      </div>
    </div>
  );
}
