"use client";

import { useState, useEffect, useRef, type ReactNode } from "react";
import { WifiHigh } from "@phosphor-icons/react/dist/icons/WifiHigh";
import { BatteryFull } from "@phosphor-icons/react/dist/icons/BatteryFull";
import { gsap, useGSAP } from "@/lib/gsap";
import { triangleColor, PopoverHeader, FilterTabs, DeployNotification } from "./MockupParts";
import type { FilterTab, ZoomPhase } from "./mockData";

function formatMenuBarDate(date: Date): string {
  const day = date.toLocaleDateString("en-US", { weekday: "short" });
  const month = date.toLocaleDateString("en-US", { month: "short" });
  const d = date.getDate();
  const time = date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
  return `${day} ${month} ${d}\u2009${time}`;
}

/* ── MacOSMenuBar ─────────────────────────────────────────── */

function MacOSMenuBar({
  phase,
  progress,
}: {
  phase: string;
  progress: number;
}) {
  const [now, setNow] = useState(() => formatMenuBarDate(new Date()));

  useEffect(() => {
    const id = setInterval(() => setNow(formatMenuBarDate(new Date())), 30_000);
    return () => clearInterval(id);
  }, []);

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
          {now}
        </span>
      </div>
    </div>
  );
}

/* ── AppMockup (shared frame) ─────────────────────────────── */

export function AppMockup({
  zoomPhase = "normal",
  phase,
  progress,
  activeTab,
  activeProject,
  notificationVisible,
  notificationExiting,
  progressKey,
  sceneDuration,
  children,
}: {
  zoomPhase?: ZoomPhase;
  phase: string;
  progress: number;
  activeTab: FilterTab;
  activeProject?: string | null;
  notificationVisible: boolean;
  notificationExiting: boolean;
  progressKey: number;
  sceneDuration: number;
  children: ReactNode;
}) {
  const zoomRef = useRef<HTMLDivElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const progressBarRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Zoom animation
  useGSAP(
    () => {
      if (!zoomRef.current) return;
      const isZoomed = zoomPhase === "zooming-in" || zoomPhase === "zoomed";

      if (zoomPhase === "zooming-in" || zoomPhase === "zoomed") {
        gsap.to(zoomRef.current, {
          scale: 2.5,
          duration: 0.6,
          ease: "power3.inOut",
          transformOrigin: "100% 3%",
        });
        if (popoverRef.current) {
          gsap.to(popoverRef.current, { autoAlpha: 0, duration: 0.3 });
        }
      } else if (zoomPhase === "zooming-out") {
        gsap.to(zoomRef.current, {
          scale: 1,
          duration: 1.2,
          ease: "power3.inOut",
        });
        if (popoverRef.current) {
          gsap.to(popoverRef.current, { autoAlpha: 1, duration: 0.8, delay: 0.3 });
        }
      } else {
        // normal — snap to default (no animation on initial render)
        gsap.set(zoomRef.current, { scale: 1 });
        if (popoverRef.current) {
          gsap.set(popoverRef.current, { autoAlpha: 1 });
        }
      }
    },
    { dependencies: [zoomPhase], scope: containerRef }
  );

  // Pill progress bar animation
  useGSAP(
    () => {
      if (!progressBarRef.current) return;
      const mm = gsap.matchMedia();
      mm.add("(prefers-reduced-motion: no-preference)", () => {
        gsap.fromTo(
          progressBarRef.current,
          { width: "0%" },
          {
            width: "100%",
            duration: sceneDuration / 1000,
            ease: "none",
          }
        );
      });
      mm.add("(prefers-reduced-motion: reduce)", () => {
        gsap.set(progressBarRef.current, { width: "100%" });
      });
    },
    { dependencies: [progressKey, sceneDuration], scope: containerRef }
  );

  return (
    <div ref={containerRef} className="relative overflow-hidden rounded-xl border border-white/[0.08] bg-[#1a1a1a] shadow-2xl">
      {/* Scene progress bar */}
      <div className="h-[2px] w-full bg-white/10">
        <div ref={progressBarRef} className="h-full bg-accent-blue" style={{ width: 0 }} />
      </div>

      <div ref={zoomRef}>
        <MacOSMenuBar phase={phase} progress={progress} />

        <DeployNotification
          visible={notificationVisible}
          exiting={notificationExiting}
        />

        <div className="relative px-4 pt-2 pb-4 bg-gradient-to-b from-[#1a1a1a] to-[#111]">
          <div className="ml-auto w-full max-w-[375px] mr-[52px]">
            <div ref={popoverRef}>
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
                <PopoverHeader activeProject={activeProject} />
                <FilterTabs activeTab={activeTab} />

                {/* Scene content area */}
                <div className="relative" style={{ minHeight: 280 }}>
                  {children}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
