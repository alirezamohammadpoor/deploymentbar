"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import {
  ArrowsClockwise,
  GearSix,
  Copy,
  ArrowSquareOut,
  ArrowCounterClockwise,
  Check,
  Globe,
  GitBranch,
  WifiHigh,
  BatteryFull,
} from "@phosphor-icons/react";
import { useDeployAnimation } from "../hooks/useDeployAnimation";

type DeploymentStatus = "ready" | "building" | "error";
type Environment = "Production" | "Preview";
type FilterTab = "All" | "Production" | "Preview";

interface Deployment {
  id: string;
  project: string;
  branch: string;
  status: DeploymentStatus;
  commit: string;
  author: string;
  env: Environment;
  duration: string;
  time: string;
}

const deployments: Deployment[] = [
  {
    id: "dpl_1",
    project: "web-app",
    branch: "main",
    status: "ready",
    commit: "Fix navbar responsive layout",
    author: "sarah",
    env: "Production",
    duration: "48s",
    time: "2m ago",
  },
  {
    id: "dpl_2",
    project: "api-server",
    branch: "feat/auth",
    status: "building",
    commit: "Add OAuth2 PKCE flow",
    author: "alex",
    env: "Preview",
    duration: "1m 12s",
    time: "30s ago",
  },
  {
    id: "dpl_3",
    project: "docs",
    branch: "main",
    status: "ready",
    commit: "Update API reference docs",
    author: "mike",
    env: "Production",
    duration: "32s",
    time: "15m ago",
  },
  {
    id: "dpl_4",
    project: "dashboard",
    branch: "fix/charts",
    status: "error",
    commit: "Refactor chart components",
    author: "sarah",
    env: "Preview",
    duration: "2m 5s",
    time: "5m ago",
  },
  {
    id: "dpl_5",
    project: "landing-page",
    branch: "main",
    status: "ready",
    commit: "Update hero section copy",
    author: "alex",
    env: "Production",
    duration: "29s",
    time: "1h ago",
  },
];

function StatusDot({ status }: { status: DeploymentStatus }) {
  const colors: Record<DeploymentStatus, string> = {
    ready: "bg-status-ready",
    building: "bg-status-building animate-pulse-building",
    error: "bg-status-error",
  };
  return <span className={`h-2 w-2 shrink-0 rounded-full ${colors[status]}`} />;
}

/* ── Color helpers for deploy animation ───────────────────── */

function lerpColor(a: [number, number, number], b: [number, number, number], t: number): string {
  const r = Math.round(a[0] + (b[0] - a[0]) * t);
  const g = Math.round(a[1] + (b[1] - a[1]) * t);
  const bl = Math.round(a[2] + (b[2] - a[2]) * t);
  return `rgb(${r}, ${g}, ${bl})`;
}

const ORANGE: [number, number, number] = [245, 158, 11];
const AMBER: [number, number, number] = [234, 179, 8];
const GREEN: [number, number, number] = [0, 200, 83];

function triangleColor(progress: number): string {
  if (progress <= 0.6) return lerpColor(ORANGE, AMBER, progress / 0.6);
  return lerpColor(AMBER, GREEN, (progress - 0.6) / 0.4);
}

/* ── DeployNotification ──────────────────────────────────── */

function DeployNotification({ phase }: { phase: string }) {
  const [visible, setVisible] = useState(false);
  const [exiting, setExiting] = useState(false);

  useEffect(() => {
    if (phase === "complete") {
      setVisible(true);
      setExiting(false);
    } else if (visible) {
      setExiting(true);
      const timer = setTimeout(() => {
        setVisible(false);
        setExiting(false);
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [phase]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!visible) return null;

  return (
    <div
      className={`
        absolute top-[34px] right-3 z-10
        w-[280px] rounded-xl border border-white/10 bg-white/10 p-3 shadow-2xl backdrop-blur-xl
        ${exiting ? "deploy-notification-exit" : "deploy-notification-enter"}
      `}
    >
      <div className="flex items-start gap-3">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#1a1a1a] text-white text-base">
          ▲
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-medium text-white">DeployBar</span>
            <span className="text-[10px] text-white/40">now</span>
          </div>
          <p className="mt-0.5 text-[12px] font-medium text-white/90">
            Deployment Ready
          </p>
          <p className="text-[11px] text-white/50">
            web-app deployed to production
          </p>
        </div>
      </div>
    </div>
  );
}

function DeploymentRow({ deployment }: { deployment: Deployment }) {
  const [expanded, setExpanded] = useState(false);
  const [copied, setCopied] = useState(false);

  function handleCopy() {
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div>
      <button
        type="button"
        onClick={() => setExpanded(!expanded)}
        className="flex w-full items-start gap-3 rounded-lg px-3 py-2.5 text-left hover:bg-[#111] transition-colors cursor-pointer"
      >
        <div className="mt-1.5">
          <StatusDot status={deployment.status} />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="text-[13px] font-medium text-text-primary">
              {deployment.project}
            </span>
            <span className="font-mono text-[10px] text-text-secondary">
              {deployment.duration}
            </span>
            <span className="text-[10px] text-text-secondary">
              {deployment.time}
            </span>
          </div>
          <p className="mt-0.5 truncate text-xs text-text-secondary">
            {deployment.commit}
          </p>
          <div className="mt-1 flex items-center gap-2">
            <span
              className={`rounded px-1.5 py-0.5 text-[10px] font-medium ${
                deployment.env === "Production"
                  ? "bg-accent-blue/10 text-accent-blue"
                  : "bg-text-secondary/10 text-text-secondary"
              }`}
            >
              {deployment.env}
            </span>
            <span className="flex items-center gap-1 text-[10px] text-text-secondary">
              <GitBranch size={10} />
              <span className="font-mono">{deployment.branch}</span>
            </span>
            <span className="text-[10px] text-text-secondary">
              by {deployment.author}
            </span>
          </div>
        </div>
      </button>

      {expanded && (
        <div className="mx-3 mb-2 flex flex-wrap gap-2 rounded-lg border border-card-border bg-[#050505] px-3 py-2.5">
          <button
            type="button"
            onClick={handleCopy}
            className="flex items-center gap-1.5 rounded-md border border-card-border px-2.5 py-1.5 text-[11px] text-text-secondary hover:text-text-primary hover:border-text-secondary/30 transition-colors cursor-pointer"
          >
            {copied ? <Check size={12} /> : <Copy size={12} />}
            {copied ? "Copied" : "Copy URL"}
          </button>
          <button
            type="button"
            className="flex items-center gap-1.5 rounded-md border border-card-border px-2.5 py-1.5 text-[11px] text-text-secondary hover:text-text-primary hover:border-text-secondary/30 transition-colors cursor-pointer"
          >
            <Globe size={12} />
            Open in Browser
          </button>
          <button
            type="button"
            className="flex items-center gap-1.5 rounded-md border border-card-border px-2.5 py-1.5 text-[11px] text-text-secondary hover:text-text-primary hover:border-text-secondary/30 transition-colors cursor-pointer"
          >
            <ArrowSquareOut size={12} />
            Open in Vercel
          </button>
          <button
            type="button"
            className="flex items-center gap-1.5 rounded-md border border-card-border px-2.5 py-1.5 text-[11px] text-text-secondary hover:text-text-primary hover:border-text-secondary/30 transition-colors cursor-pointer"
          >
            <ArrowsClockwise size={12} />
            Redeploy
          </button>
          {deployment.env === "Production" && deployment.status === "ready" && (
            <button
              type="button"
              className="flex items-center gap-1.5 rounded-md border border-status-error/30 px-2.5 py-1.5 text-[11px] text-status-error hover:border-status-error/60 transition-colors cursor-pointer"
            >
              <ArrowCounterClockwise size={12} />
              Rollback
            </button>
          )}
        </div>
      )}
    </div>
  );
}

function MacOSMenuBar({ phase, progress }: { phase: string; progress: number }) {
  return (
    <div className="flex h-[26px] items-center justify-between bg-black/60 backdrop-blur-xl border-b border-white/10 px-3 text-[13px] select-none">
      {/* Left side: Apple logo + app menus */}
      <div className="flex items-center gap-4">
        <span className="text-[15px] text-white/90"></span>
        <span className="font-semibold text-white">DeployBar</span>
        <div className="flex items-center gap-3 text-white/50">
          <span>File</span>
          <span>Edit</span>
          <span>View</span>
          <span>Window</span>
          <span>Help</span>
        </div>
      </div>

      {/* Right side: System tray */}
      <div className="flex items-center gap-2.5 text-white/60">
        <WifiHigh size={14} weight="bold" className="text-white/60" />
        <BatteryFull size={16} weight="bold" className="text-white/60" />
        {/* Control Center dots */}
        <svg width="14" height="14" viewBox="0 0 14 14" className="text-white/60">
          <rect x="2" y="3" width="4" height="4" rx="1" fill="currentColor" />
          <rect x="8" y="3" width="4" height="4" rx="1" fill="currentColor" />
          <rect x="2" y="9" width="4" height="4" rx="1" fill="currentColor" />
          <rect x="8" y="9" width="4" height="4" rx="1" fill="currentColor" />
        </svg>
        {/* DeployBar tray icon - animated during deploy */}
        <div className={`relative flex items-center justify-center rounded px-1 py-0.5 bg-white/10 ${phase === "complete" ? "deploy-triangle-complete" : ""}`}>
          <span
            className="text-[12px] font-medium"
            style={{
              color: phase === "building"
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

export function InteractiveDemo() {
  const [activeTab, setActiveTab] = useState<FilterTab>("All");
  const { phase, progress, deploy } = useDeployAnimation();

  // Listen for deploy trigger from the hero section
  useEffect(() => {
    const handler = () => deploy();
    window.addEventListener("deploybar-deploy", handler);
    return () => window.removeEventListener("deploybar-deploy", handler);
  }, [deploy]);

  const filtered =
    activeTab === "All"
      ? deployments
      : deployments.filter((d) => d.env === activeTab);

  return (
    <section id="demo" className="mx-auto max-w-6xl px-6 py-12">
      <div className="mx-auto w-full max-w-[680px]">
        {/* Screen frame */}
        <div className="relative overflow-hidden rounded-xl border border-white/[0.08] bg-[#1a1a1a] shadow-2xl">
          {/* macOS Menu Bar */}
          <MacOSMenuBar phase={phase} progress={progress} />

          {/* macOS notification overlay */}
          <DeployNotification phase={phase} />

          {/* Popover area */}
          <div className="relative px-4 pt-2 pb-4 bg-gradient-to-b from-[#1a1a1a] to-[#111]">
            {/* Right-aligned popover */}
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
                {/* Header */}
                <div className="flex items-center justify-between border-b border-card-border px-4 py-3">
                  <div className="flex items-center gap-2">
                    <Image
                      src="/app-icon.png"
                      alt="DeployBar"
                      width={18}
                      height={18}
                      className="rounded"
                    />
                    <span className="text-sm font-medium text-text-primary">
                      DeployBar
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <button type="button" className="rounded p-1 text-text-secondary hover:text-text-primary transition-colors cursor-pointer">
                      <ArrowsClockwise size={14} />
                    </button>
                    <button type="button" className="rounded p-1 text-text-secondary hover:text-text-primary transition-colors cursor-pointer">
                      <GearSix size={14} />
                    </button>
                  </div>
                </div>

                {/* Filter tabs */}
                <div className="flex border-b border-card-border">
                  {(["All", "Production", "Preview"] as FilterTab[]).map((tab) => (
                    <button
                      key={tab}
                      type="button"
                      onClick={() => setActiveTab(tab)}
                      className={`flex-1 py-2 text-xs font-medium transition-colors cursor-pointer ${
                        activeTab === tab
                          ? "text-text-primary border-b-2 border-accent-blue"
                          : "text-text-secondary hover:text-text-primary"
                      }`}
                    >
                      {tab}
                    </button>
                  ))}
                </div>

                {/* Deployment list */}
                <div className="max-h-[360px] overflow-y-auto">
                  {filtered.map((d) => (
                    <DeploymentRow key={d.id} deployment={d} />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
