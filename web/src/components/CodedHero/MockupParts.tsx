"use client";

import { Copy } from "@phosphor-icons/react/dist/icons/Copy";
import { Globe } from "@phosphor-icons/react/dist/icons/Globe";
import { ArrowSquareOut } from "@phosphor-icons/react/dist/icons/ArrowSquareOut";
import { ArrowsClockwise } from "@phosphor-icons/react/dist/icons/ArrowsClockwise";
import { ArrowCounterClockwise } from "@phosphor-icons/react/dist/icons/ArrowCounterClockwise";
import { GitBranch } from "@phosphor-icons/react/dist/icons/GitBranch";
import type { DeploymentStatus, MockDeployment, FilterTab } from "./mockData";

/* ── Color helpers for deploy animation ───────────────────── */

export function lerpColor(
  a: [number, number, number],
  b: [number, number, number],
  t: number
): string {
  const r = Math.round(a[0] + (b[0] - a[0]) * t);
  const g = Math.round(a[1] + (b[1] - a[1]) * t);
  const bl = Math.round(a[2] + (b[2] - a[2]) * t);
  return `rgb(${r}, ${g}, ${bl})`;
}

export const ORANGE: [number, number, number] = [245, 158, 11];
export const AMBER: [number, number, number] = [234, 179, 8];
export const GREEN: [number, number, number] = [0, 200, 83];

export function triangleColor(progress: number): string {
  if (progress <= 0.6) return lerpColor(ORANGE, AMBER, progress / 0.6);
  return lerpColor(AMBER, GREEN, (progress - 0.6) / 0.4);
}

/* ── StatusDot ────────────────────────────────────────────── */

export function StatusDot({ status }: { status: DeploymentStatus }) {
  const colors: Record<DeploymentStatus, string> = {
    ready: "bg-status-ready",
    building: "bg-status-building animate-pulse-building",
    error: "bg-status-error",
  };
  return (
    <span className={`h-2 w-2 shrink-0 rounded-full ${colors[status]}`} />
  );
}

/* ── FilterTabs ───────────────────────────────────────────── */

export function FilterTabs({
  activeTab,
  onTabChange,
}: {
  activeTab: FilterTab;
  onTabChange?: (tab: FilterTab) => void;
}) {
  return (
    <div className="flex border-b border-card-border">
      {(["All", "Production", "Preview"] as FilterTab[]).map((tab) => (
        <button
          key={tab}
          type="button"
          onClick={() => onTabChange?.(tab)}
          className={`flex-1 py-2 text-xs font-medium transition-colors ${
            activeTab === tab
              ? "text-text-primary border-b-2 border-accent-blue"
              : "text-text-secondary"
          }`}
        >
          {tab}
        </button>
      ))}
    </div>
  );
}

/* ── PopoverHeader ────────────────────────────────────────── */

export function PopoverHeader() {
  return (
    <div className="flex items-center justify-between border-b border-card-border px-4 py-3">
      <div className="flex items-center gap-2">
        <div className="flex h-[18px] w-[18px] items-center justify-center rounded bg-black text-[10px] text-white">
          ▲
        </div>
        <span className="text-sm font-medium text-text-primary">
          DeployBar
        </span>
      </div>
      <div className="flex items-center gap-2">
        <span className="rounded p-1 text-text-secondary">
          <ArrowsClockwise size={14} />
        </span>
        <span className="rounded p-1 text-text-secondary">
          <svg
            width={14}
            height={14}
            viewBox="0 0 256 256"
            fill="currentColor"
          >
            <path d="M128,80a48,48,0,1,0,48,48A48.05,48.05,0,0,0,128,80Zm0,80a32,32,0,1,1,32-32A32,32,0,0,1,128,160Zm109.94-52.79a8,8,0,0,0-6.39-5.67l-14.83-2.56a96.11,96.11,0,0,0-8.07-19.54l8.2-12.35a8,8,0,0,0-1.1-8.47,136.07,136.07,0,0,0-19.87-19.87,8,8,0,0,0-8.47-1.1L175.06,46l-.1,0A96.11,96.11,0,0,0,155.41,38l-2.56-14.83a8,8,0,0,0-5.67-6.39,111.53,111.53,0,0,0-38.36,0,8,8,0,0,0-5.67,6.39L100.59,38a96.11,96.11,0,0,0-19.54,8.07L68.7,37.84a8,8,0,0,0-8.47,1.1A136.07,136.07,0,0,0,40.36,58.81a8,8,0,0,0-1.1,8.47L47.46,79.63l0,.1A96.11,96.11,0,0,0,39.38,99.27l-14.83,2.56a8,8,0,0,0-6.39,5.67,111.53,111.53,0,0,0,0,38.36,8,8,0,0,0,6.39,5.67L39.38,154a96.11,96.11,0,0,0,8.07,19.54l-8.2,12.35a8,8,0,0,0,1.1,8.47,136.07,136.07,0,0,0,19.87,19.87,8,8,0,0,0,8.47,1.1l12.35-8.2.1,0a96.11,96.11,0,0,0,19.54,8.07l2.56,14.83a8,8,0,0,0,5.67,6.39,111.53,111.53,0,0,0,38.36,0,8,8,0,0,0,5.67-6.39l2.56-14.83a96.11,96.11,0,0,0,19.54-8.07l12.35,8.2a8,8,0,0,0,8.47-1.1,136.07,136.07,0,0,0,19.87-19.87,8,8,0,0,0,1.1-8.47L208.54,173.6l0-.1A96.11,96.11,0,0,0,216.62,154l14.83-2.56a8,8,0,0,0,6.39-5.67A111.53,111.53,0,0,0,237.94,107.21ZM128,176a48,48,0,1,1,48-48A48.05,48.05,0,0,1,128,176Z" />
          </svg>
        </span>
      </div>
    </div>
  );
}

/* ── ActionButtons ────────────────────────────────────────── */

export type ActionButtonId =
  | "copy"
  | "browser"
  | "vercel"
  | "redeploy"
  | "rollback";

const actionButtonBase =
  "flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-[11px] transition-all duration-200";

export function ActionButtons({
  showRollback = false,
  highlightedButton,
}: {
  showRollback?: boolean;
  highlightedButton?: ActionButtonId | null;
}) {
  const highlight = (id: ActionButtonId) =>
    highlightedButton === id
      ? id === "rollback"
        ? "border-status-error/60 text-status-error shadow-[0_0_12px_rgba(238,0,0,0.3)] scale-105"
        : "border-accent-blue/60 text-accent-blue shadow-[0_0_12px_rgba(0,112,243,0.3)] scale-105"
      : id === "rollback"
        ? "border-status-error/30 text-status-error"
        : "border-card-border text-text-secondary";

  return (
    <div className="mx-3 mb-2 flex flex-wrap gap-2 rounded-lg border border-card-border bg-[#050505] px-3 py-2.5">
      <span className={`${actionButtonBase} ${highlight("copy")}`}>
        <Copy size={12} />
        Copy URL
      </span>
      <span className={`${actionButtonBase} ${highlight("browser")}`}>
        <Globe size={12} />
        Open in Browser
      </span>
      <span className={`${actionButtonBase} ${highlight("vercel")}`}>
        <ArrowSquareOut size={12} />
        Open in Vercel
      </span>
      <span className={`${actionButtonBase} ${highlight("redeploy")}`}>
        <ArrowsClockwise size={12} />
        Redeploy
      </span>
      {showRollback && (
        <span className={`${actionButtonBase} ${highlight("rollback")}`}>
          <ArrowCounterClockwise size={12} />
          Rollback
        </span>
      )}
    </div>
  );
}

/* ── DeployNotification ───────────────────────────────────── */

export function DeployNotification({
  visible,
  exiting,
}: {
  visible: boolean;
  exiting: boolean;
}) {
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
            <span className="text-[12px] font-medium text-white">
              DeployBar
            </span>
            <span className="text-[10px] text-white/40">now</span>
          </div>
          <p className="mt-0.5 text-[12px] font-medium text-white/90">
            Deployment Ready
          </p>
          <p className="text-[11px] text-white/50">
            api-server deployed to preview
          </p>
        </div>
      </div>
    </div>
  );
}

/* ── DeploymentRow ────────────────────────────────────────── */

export function DeploymentRow({
  deployment,
  expanded = false,
  highlightedButton,
  tooltip,
}: {
  deployment: MockDeployment;
  expanded?: boolean;
  highlightedButton?: ActionButtonId | null;
  tooltip?: string | null;
}) {
  const showRollback =
    deployment.env === "Production" && deployment.status === "ready";

  return (
    <div>
      <div className="flex w-full items-start gap-3 rounded-lg px-3 py-2.5 text-left transition-colors">
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
      </div>

      {expanded && (
        <div className="relative coded-hero-row-expand">
          <ActionButtons
            showRollback={showRollback}
            highlightedButton={highlightedButton}
          />
          {tooltip && (
            <div className="coded-hero-tooltip absolute -top-7 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-md bg-white/10 px-3 py-1.5 text-[11px] text-white/80 backdrop-blur-md border border-white/10">
              {tooltip}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
