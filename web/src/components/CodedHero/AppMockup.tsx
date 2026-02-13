"use client";

import type { ReactNode } from "react";
import { WifiHigh } from "@phosphor-icons/react/dist/icons/WifiHigh";
import { BatteryFull } from "@phosphor-icons/react/dist/icons/BatteryFull";
import { triangleColor, PopoverHeader, FilterTabs, DeployNotification } from "./MockupParts";
import type { FilterTab } from "./mockData";

/* ── MacOSMenuBar ─────────────────────────────────────────── */

function MacOSMenuBar({
  phase,
  progress,
}: {
  phase: string;
  progress: number;
}) {
  return (
    <div className="flex h-[26px] items-center justify-between bg-black/60 backdrop-blur-xl border-b border-white/10 px-3 text-[13px] select-none">
      <div className="flex items-center gap-4">
        <span className="text-[15px] text-white/90"></span>
        <span className="font-semibold text-white">DeployBar</span>
      </div>

      <div className="flex items-center gap-2.5 text-white/60">
        <WifiHigh size={14} weight="bold" className="text-white/60" />
        <BatteryFull size={16} weight="bold" className="text-white/60" />
        <svg
          width="14"
          height="14"
          viewBox="0 0 14 14"
          className="text-white/60"
        >
          <rect x="2" y="3" width="4" height="4" rx="1" fill="currentColor" />
          <rect x="8" y="3" width="4" height="4" rx="1" fill="currentColor" />
          <rect x="2" y="9" width="4" height="4" rx="1" fill="currentColor" />
          <rect x="8" y="9" width="4" height="4" rx="1" fill="currentColor" />
        </svg>
        <div
          className={`relative flex items-center justify-center rounded px-1 py-0.5 bg-white/10 ${
            phase === "complete" ? "deploy-triangle-complete" : ""
          }`}
        >
          <span
            className="text-[12px] font-medium"
            style={{
              color:
                phase === "building"
                  ? triangleColor(progress)
                  : phase === "complete"
                    ? "#00c853"
                    : "rgba(255,255,255,0.6)",
              transition: "color 0.05s linear",
            }}
          >
            ▲
          </span>
        </div>
        <span className="text-white/50 text-[12px] tabular-nums">
          Thu Feb 12 &thinsp;3:42 PM
        </span>
      </div>
    </div>
  );
}

/* ── AppMockup (shared frame) ─────────────────────────────── */

export function AppMockup({
  phase,
  progress,
  activeTab,
  notificationVisible,
  notificationExiting,
  children,
}: {
  phase: string;
  progress: number;
  activeTab: FilterTab;
  notificationVisible: boolean;
  notificationExiting: boolean;
  children: ReactNode;
}) {
  return (
    <div className="relative overflow-hidden rounded-xl border border-white/[0.08] bg-[#1a1a1a] shadow-2xl">
      <MacOSMenuBar phase={phase} progress={progress} />

      <DeployNotification
        visible={notificationVisible}
        exiting={notificationExiting}
      />

      <div className="relative px-4 pt-2 pb-4 bg-gradient-to-b from-[#1a1a1a] to-[#111]">
        <div className="ml-auto w-full max-w-[375px] mr-[52px]">
          {/* Popover arrow */}
          <div className="flex justify-end mr-[18px]">
            <div
              className="h-2.5 w-4"
              style={{
                clipPath: "polygon(50% 0%, 0% 100%, 100% 100%)",
                background: "#0a0a0a",
              }}
            />
          </div>

          {/* Popover card */}
          <div className="overflow-hidden rounded-xl border border-card-border bg-card-bg shadow-2xl">
            <PopoverHeader />
            <FilterTabs activeTab={activeTab} />

            {/* Scene content area */}
            <div className="relative" style={{ minHeight: 280 }}>
              {children}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
