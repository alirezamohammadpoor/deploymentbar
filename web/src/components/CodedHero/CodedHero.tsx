"use client";

import { useState, useCallback, useEffect } from "react";
import { DownloadSimple } from "@phosphor-icons/react/dist/icons/DownloadSimple";
import { usePillCycle } from "../../hooks/usePillCycle";
import { AppMockup } from "./AppMockup";
import { SceneRenderer } from "./SceneRenderer";
import { MonitoringScene } from "./scenes/MonitoringScene";
import { QuickActionsScene } from "./scenes/QuickActionsScene";
import { FilterScene } from "./scenes/FilterScene";
import type { FilterTab } from "./mockData";

const features = [
  {
    id: "monitoring",
    label: "Monitoring",
    description:
      "Track builds, CI checks, and deployment status in real time",
  },
  {
    id: "actions",
    label: "Quick Actions",
    description:
      "Copy URLs, open in browser, view on Vercel, redeploy — all in one click",
  },
  {
    id: "filter",
    label: "Filter",
    description:
      "Filter by project, environment, or branch to find any deployment fast",
  },
];

const SCENE_COUNT = features.length;
const SCENE_DURATIONS = [6500, 6000, 10500];

type ZoomPhase = "zooming-in" | "zoomed" | "zooming-out" | "normal";

export function CodedHero() {
  const { activeIdx, progressKey, handlePillClick } = usePillCycle(SCENE_COUNT, {}, SCENE_DURATIONS);

  // Zoom state (driven by MonitoringScene)
  const [zoomPhase, setZoomPhase] = useState<ZoomPhase>("normal");

  // When switching TO monitoring scene, kick off zoom-in
  useEffect(() => {
    if (activeIdx === 0) {
      setZoomPhase("zooming-in");
    }
  }, [activeIdx]);

  // Derive effective zoom (only applies during scene 0)
  const effectiveZoom: ZoomPhase = activeIdx === 0 ? zoomPhase : "normal";

  // Menu bar state (driven by MonitoringScene)
  const [menuPhase, setMenuPhase] = useState("idle");
  const [menuProgress, setMenuProgress] = useState(0);

  // Notification state (driven by MonitoringScene)
  const [notifVisible, setNotifVisible] = useState(false);
  const [notifExiting, setNotifExiting] = useState(false);

  // Filter tab state (driven by FilterScene, or default per scene)
  const [filterTab, setFilterTab] = useState<FilterTab>("All");

  // Project filter state (driven by FilterScene)
  const [projectFilter, setProjectFilter] = useState<string | null>(null);

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

  const handleProjectChange = useCallback((project: string | null) => {
    setProjectFilter(project);
  }, []);

  const handleZoom = useCallback((phase: ZoomPhase) => {
    setZoomPhase(phase);
  }, []);

  // Reset state when scene changes
  const activeTab = activeIdx === 2 ? filterTab : "All";
  const activeProject = activeIdx === 2 ? projectFilter : null;

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
              onZoom={handleZoom}
            />
          );
        case 1:
          return <QuickActionsScene active={isActive} />;
        case 2:
          return (
            <FilterScene
              active={isActive}
              onTabChange={handleTabChange}
              onProjectChange={handleProjectChange}
            />
          );
        default:
          return null;
      }
    },
    [handleNotification, handlePhaseChange, handleTabChange, handleProjectChange, handleZoom]
  );

  return (
    <div className="relative z-10 mx-auto flex w-full max-w-4xl flex-col items-center text-center">
      {/* Headline */}
      <h1 className="hero-enter max-w-3xl text-4xl font-medium leading-tight tracking-tight text-text-primary sm:text-5xl md:text-[64px] md:leading-[1.1]">
        Track every Vercel deployment{" "}
        <span className="text-accent-blue">from your menu bar</span>
      </h1>

      {/* Subheadline */}
      <p className="hero-enter-delay-1 mt-6 max-w-xl text-base leading-relaxed text-text-secondary sm:text-lg">
        Monitor builds without switching tabs or breaking focus. Know the moment
        a deployment succeeds or fails.
      </p>

      {/* CTA */}
      <div className="hero-enter-delay-2 mt-10 flex flex-col items-center gap-3">
        <div className="flex items-center gap-4">
          <a
            href="#download"
            className="hero-shine inline-flex items-center justify-center gap-2 rounded-lg bg-accent-blue px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#005bd4]"
          >
            <DownloadSimple size={18} weight="bold" />
            Download for macOS
          </a>
          <a
            href="https://github.com/nicktrienenern/deploybar"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors"
          >
            View on GitHub &rarr;
          </a>
        </div>
        <p className="text-[14px] text-text-secondary">
          Sign in with Vercel and see deployments instantly.
        </p>
        <p className="text-xs text-text-secondary/50">
          Free public beta &middot; macOS 14+
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
            </button>
          ))}
        </div>
      </div>

      {/* Feature description */}
      <p
        key={features[activeIdx].id}
        className="mt-3 text-sm text-text-secondary animate-fade-in-up"
        style={{ animationDuration: "0.3s" }}
      >
        {features[activeIdx].description}
      </p>

      {/* Coded mockup (replaces video player) */}
      <div className="hero-enter-delay-4 relative mt-8 w-full">
        <AppMockup
          zoomPhase={effectiveZoom}
          phase={effectivePhase}
          progress={effectiveProgress}
          activeTab={activeTab}
          activeProject={activeProject}
          notificationVisible={effectiveNotifVisible}
          notificationExiting={effectiveNotifExiting}
          progressKey={progressKey}
          sceneDuration={SCENE_DURATIONS[activeIdx]}
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
