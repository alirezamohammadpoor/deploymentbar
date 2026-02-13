"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { DownloadSimple } from "@phosphor-icons/react";

const features = [
  { id: "monitoring", label: "Monitoring", video: "/videos/monitoring.mp4" },
  { id: "actions", label: "Quick Actions", video: "/videos/actions.mp4" },
  { id: "rollback", label: "Rollback", video: "/videos/rollback.mp4" },
  { id: "filter", label: "Filter", video: "/videos/filter.mp4" },
  { id: "browser", label: "Browser", video: "/videos/browser.mp4" },
];

const CYCLE_INTERVAL = 6000;
const INACTIVITY_DELAY = 10000;

export function HeroShowcase() {
  const [activeIdx, setActiveIdx] = useState(0);
  const [showFront, setShowFront] = useState(true);
  const [frontSrc, setFrontSrc] = useState(features[0].video);
  const [backSrc, setBackSrc] = useState(features[0].video);
  const [videoError, setVideoError] = useState<Record<string, boolean>>({});
  const [progressKey, setProgressKey] = useState(0);

  const autoCycleRef = useRef(true);
  const cycleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const inactivityTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const reducedMotionRef = useRef(false);

  // Check reduced motion preference
  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    reducedMotionRef.current = mq.matches;
    const handler = (e: MediaQueryListEvent) => {
      reducedMotionRef.current = e.matches;
    };
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  // Crossfade to new video
  const switchTo = useCallback(
    (idx: number) => {
      const src = features[idx].video;
      if (showFront) {
        setBackSrc(src);
        setShowFront(false);
      } else {
        setFrontSrc(src);
        setShowFront(true);
      }
      setActiveIdx(idx);
      setProgressKey((k) => k + 1);
    },
    [showFront]
  );

  // Auto-cycle logic
  useEffect(() => {
    if (reducedMotionRef.current) return;

    const clearCycle = () => {
      if (cycleTimerRef.current) {
        clearTimeout(cycleTimerRef.current);
        cycleTimerRef.current = null;
      }
    };

    const startCycle = () => {
      clearCycle();
      if (!autoCycleRef.current) return;
      cycleTimerRef.current = setTimeout(() => {
        const next = (activeIdx + 1) % features.length;
        switchTo(next);
      }, CYCLE_INTERVAL);
    };

    startCycle();
    return clearCycle;
  }, [activeIdx, switchTo]);

  // Handle user pill click
  const handlePillClick = (idx: number) => {
    // Pause auto-cycle
    autoCycleRef.current = false;
    if (cycleTimerRef.current) {
      clearTimeout(cycleTimerRef.current);
      cycleTimerRef.current = null;
    }

    // Switch video
    if (idx !== activeIdx) {
      switchTo(idx);
    } else {
      // Reset progress bar even on same pill click
      setProgressKey((k) => k + 1);
    }

    // Restart inactivity timer
    if (inactivityTimerRef.current) {
      clearTimeout(inactivityTimerRef.current);
    }
    inactivityTimerRef.current = setTimeout(() => {
      autoCycleRef.current = true;
      // Trigger next cycle
      const next = (idx + 1) % features.length;
      switchTo(next);
    }, INACTIVITY_DELAY);
  };

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (cycleTimerRef.current) clearTimeout(cycleTimerRef.current);
      if (inactivityTimerRef.current) clearTimeout(inactivityTimerRef.current);
    };
  }, []);

  const handleVideoError = (featureId: string) => {
    setVideoError((prev) => ({ ...prev, [featureId]: true }));
  };

  const activeFeature = features[activeIdx];
  const showPlaceholder = videoError[activeFeature.id];

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
              {/* Progress bar */}
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

      {/* Video player */}
      <div className="hero-enter-delay-4 relative mt-8 w-full overflow-hidden rounded-xl border border-white/[0.08] shadow-2xl">
        <div className="relative aspect-video w-full bg-[#0a0a0a]">
          {showPlaceholder ? (
            <div className="flex h-full w-full items-center justify-center bg-[#0a0a0a]">
              <div className="text-center">
                <p className="text-lg font-medium text-text-secondary">
                  {activeFeature.label}
                </p>
                <p className="mt-1 text-sm text-text-secondary/50">
                  Recording coming soon
                </p>
              </div>
            </div>
          ) : (
            <>
              {/* Front video layer */}
              <video
                key={`front-${frontSrc}`}
                className="video-layer absolute inset-0 h-full w-full object-cover"
                style={{ opacity: showFront ? 1 : 0 }}
                src={frontSrc}
                autoPlay
                loop
                muted
                playsInline
                onError={() => {
                  const f = features.find((ft) => ft.video === frontSrc);
                  if (f) handleVideoError(f.id);
                }}
              />
              {/* Back video layer */}
              <video
                key={`back-${backSrc}`}
                className="video-layer absolute inset-0 h-full w-full object-cover"
                style={{ opacity: showFront ? 0 : 1 }}
                src={backSrc}
                autoPlay
                loop
                muted
                playsInline
                onError={() => {
                  const f = features.find((ft) => ft.video === backSrc);
                  if (f) handleVideoError(f.id);
                }}
              />
            </>
          )}
        </div>
      </div>
    </div>
  );
}
