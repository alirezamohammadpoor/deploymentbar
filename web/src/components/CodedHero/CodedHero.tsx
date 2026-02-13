"use client";

import { useState, useCallback } from "react";
import { DownloadSimple } from "@phosphor-icons/react/dist/icons/DownloadSimple";
import { usePillCycle } from "../../hooks/usePillCycle";
import { AppMockup } from "./AppMockup";
import { SceneRenderer } from "./SceneRenderer";
import { MonitoringScene } from "./scenes/MonitoringScene";
import { QuickActionsScene } from "./scenes/QuickActionsScene";
import { RollbackScene } from "./scenes/RollbackScene";
import { FilterScene } from "./scenes/FilterScene";
import { BrowserScene } from "./scenes/BrowserScene";
import type { FilterTab } from "./mockData";

const features = [
  { id: "monitoring", label: "Monitoring" },
  { id: "actions", label: "Quick Actions" },
  { id: "rollback", label: "Rollback" },
  { id: "filter", label: "Filter" },
  { id: "browser", label: "Browser" },
];

const SCENE_COUNT = features.length;

// Map scene index to the filter tab it should show
function defaultTabForScene(idx: number): FilterTab {
  if (idx === 2) return "Production"; // Rollback scene
  return "All";
}

export function CodedHero() {
  const { activeIdx, progressKey, handlePillClick } = usePillCycle(SCENE_COUNT);

  // Menu bar state (driven by MonitoringScene)
  const [menuPhase, setMenuPhase] = useState("idle");
  const [menuProgress, setMenuProgress] = useState(0);

  // Notification state (driven by MonitoringScene)
  const [notifVisible, setNotifVisible] = useState(false);
  const [notifExiting, setNotifExiting] = useState(false);

  // Filter tab state (driven by FilterScene, or default per scene)
  const [filterTab, setFilterTab] = useState<FilterTab>("All");

  const handleNotification = useCallback(
    (visible: boolean, exiting: boolean) => {
      setNotifVisible(visible);
      setNotifExiting(exiting);
    },
    []
  );

  const handlePhaseChange = useCallback(
    (phase: string, progress: number) => {
      setMenuPhase(phase);
      setMenuProgress(progress);
    },
    []
  );

  const handleTabChange = useCallback((tab: FilterTab) => {
    setFilterTab(tab);
  }, []);

  // Reset state when scene changes
  const activeTab =
    activeIdx === 3 ? filterTab : defaultTabForScene(activeIdx);

  // Reset notification/phase when leaving monitoring scene
  const effectivePhase = activeIdx === 0 ? menuPhase : "idle";
  const effectiveProgress = activeIdx === 0 ? menuProgress : 0;
  const effectiveNotifVisible = activeIdx === 0 ? notifVisible : false;
  const effectiveNotifExiting = activeIdx === 0 ? notifExiting : false;

  const renderScene = useCallback(
    (sceneIdx: number, isActive: boolean) => {
      switch (sceneIdx) {
        case 0:
          return (
            <MonitoringScene
              active={isActive}
              onNotification={handleNotification}
              onPhaseChange={handlePhaseChange}
            />
          );
        case 1:
          return <QuickActionsScene active={isActive} />;
        case 2:
          return <RollbackScene active={isActive} />;
        case 3:
          return (
            <FilterScene active={isActive} onTabChange={handleTabChange} />
          );
        case 4:
          return <BrowserScene active={isActive} />;
        default:
          return null;
      }
    },
    [handleNotification, handlePhaseChange, handleTabChange]
  );

  return (
    <div className="relative z-10 mx-auto flex w-full max-w-4xl flex-col items-center text-center">
      {/* Headline */}
      <h1 className="hero-enter max-w-3xl text-4xl font-medium leading-tight tracking-tight text-text-primary sm:text-5xl md:text-[64px] md:leading-[1.1]">
        All your deployments.{" "}
        <span className="text-accent-blue">One glance away.</span>
      </h1>

      {/* Subheadline */}
      <p className="hero-enter-delay-1 mt-6 max-w-xl text-base leading-relaxed text-text-secondary sm:text-lg">
        DeployBar lives in your menubar. See every Vercel deployment the moment
        it starts. Monitor progress. Catch failures instantly. No browser tabs.
        No context switching. Just ship.
      </p>

      {/* CTA */}
      <div className="hero-enter-delay-2 mt-10 flex flex-col items-center gap-3">
        <a
          href="#waitlist"
          className="hero-shine inline-flex items-center justify-center gap-2 rounded-lg bg-accent-blue px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#005bd4]"
        >
          <DownloadSimple size={18} weight="bold" />
          Download for macOS
        </a>
        <p className="text-xs text-text-secondary/50">
          Free during beta &middot; macOS 14+ required
        </p>
      </div>

      {/* Pill bar */}
      <div className="hero-enter-delay-3 mt-14 flex w-full justify-center overflow-x-auto snap-x snap-mandatory scrollbar-none">
        <div className="flex gap-2">
          {features.map((f, idx) => (
            <button
              key={f.id}
              type="button"
              onClick={() => handlePillClick(idx)}
              className={`relative snap-center shrink-0 rounded-full px-4 py-2 text-sm font-medium transition-colors cursor-pointer ${
                idx === activeIdx
                  ? "bg-white text-black"
                  : "text-text-secondary hover:text-text-primary hover:bg-white/5"
              }`}
            >
              {idx === activeIdx && (
                <span className="pill-dot mr-1.5 inline-block h-1.5 w-1.5 rounded-full bg-accent-blue align-middle" />
              )}
              {f.label}
              {idx === activeIdx && (
                <span
                  key={progressKey}
                  className="pill-progress-bar absolute bottom-0 left-0 h-[2px] rounded-full bg-accent-blue/60"
                />
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Coded mockup (replaces video player) */}
      <div className="hero-enter-delay-4 relative mt-8 w-full">
        <AppMockup
          phase={effectivePhase}
          progress={effectiveProgress}
          activeTab={activeTab}
          notificationVisible={effectiveNotifVisible}
          notificationExiting={effectiveNotifExiting}
        >
          <SceneRenderer
            activeIdx={activeIdx}
            sceneCount={SCENE_COUNT}
          >
            {renderScene}
          </SceneRenderer>
        </AppMockup>
      </div>
    </div>
  );
}
