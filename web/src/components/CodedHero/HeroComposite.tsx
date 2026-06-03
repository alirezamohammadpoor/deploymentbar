"use client";

import { useState, useCallback, useEffect } from "react";
import { AppMockup } from "./AppMockup";
import { MonitoringScene } from "./scenes/MonitoringScene";

/**
 * Purpose-built hero embed: the real Monitoring scene (building → ready →
 * notification) inside the app frame, with no scene-cycle chrome. Meant to be
 * enlarged and cropped so it bleeds off the bottom edge of the hero. The
 * building/deploy motion is product truth, so it's kept (and gently looped);
 * everything else stays still.
 */
export function HeroComposite() {
  const [menuPhase, setMenuPhase] = useState("idle");
  const [menuProgress, setMenuProgress] = useState(0);
  const [notifVisible, setNotifVisible] = useState(false);
  const [notifExiting, setNotifExiting] = useState(false);

  // Remount the scene on an interval to replay the deploy sequence calmly.
  const [cycle, setCycle] = useState(0);
  useEffect(() => {
    const prefersReduced =
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (prefersReduced) return;
    const id = setInterval(() => setCycle((c) => c + 1), 9000);
    return () => clearInterval(id);
  }, []);

  const handleNotification = useCallback((visible: boolean, exiting: boolean) => {
    setNotifVisible(visible);
    setNotifExiting(exiting);
  }, []);

  const handlePhaseChange = useCallback((phase: string, progress: number) => {
    setMenuPhase(phase);
    setMenuProgress(progress);
  }, []);

  return (
    <AppMockup
      variant="hero"
      phase={menuPhase}
      progress={menuProgress}
      activeTab="All"
      activeProject={null}
      notificationVisible={notifVisible}
      notificationExiting={notifExiting}
      progressKey={cycle}
      sceneDuration={9000}
    >
      <MonitoringScene
        key={cycle}
        active
        onNotification={handleNotification}
        onPhaseChange={handlePhaseChange}
        listClassName=""
      />
    </AppMockup>
  );
}
