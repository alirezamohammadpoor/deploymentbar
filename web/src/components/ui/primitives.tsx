"use client";

import type { ReactNode } from "react";

/* ── StatusDot ──────────────────────────────────────────────
   The page's single saturated accent point: a small round status
   glyph. Green/amber/red are deploymentbar's real visual language;
   queued/canceled are dim gray (matches the Figma component set). */

export type DeployStatus =
  | "ready"
  | "building"
  | "error"
  | "queued"
  | "canceled";

const STATUS_BG: Record<DeployStatus, string> = {
  ready: "bg-status-ready",
  building: "bg-status-building",
  error: "bg-status-error",
  queued: "bg-status-queued",
  canceled: "bg-status-canceled",
};

export function StatusDot({
  status,
  size = 8,
  pulse,
}: {
  status: DeployStatus;
  size?: number;
  pulse?: boolean;
}) {
  const shouldPulse = pulse ?? (status === "building" || status === "queued");
  return (
    <span
      aria-hidden
      className={`inline-block shrink-0 rounded-full ${STATUS_BG[status]} ${
        shouldPulse ? "animate-pulse-building" : ""
      }`}
      style={{ width: size, height: size }}
    />
  );
}

/* ── SectionLabel — the N.0 spine marker ────────────────────
   Dim mono numeral + uppercase label + thin trailing arrow. */

export function SectionLabel({
  index,
  label,
}: {
  index?: string; // optional — omitted site-wide (no Linear-style numbering)
  label: string;
}) {
  return (
    <div className="flex items-center gap-2 font-mono text-[12px]">
      {index ? <span className="text-text-dim tabular-nums">{index}</span> : null}
      <span className="uppercase tracking-[0.12em] text-text-secondary">
        {label}
      </span>
      <span aria-hidden className="text-text-dim">
        →
      </span>
    </div>
  );
}

/* ── SubIndex — the N.N two-column dim index ────────────────
   Lands low in a section; numerals dimmer than labels. */

export function SubIndex({
  items,
  className = "",
}: {
  items: { index: string; label: string }[];
  className?: string;
}) {
  return (
    <dl className={`font-mono text-[12px] ${className}`}>
      {items.map((it) => (
        <div key={it.index} className="flex gap-3 py-1">
          <dt className="tabular-nums text-text-dim">{it.index}</dt>
          <dd className="text-text-secondary">{it.label}</dd>
        </div>
      ))}
    </dl>
  );
}

/* ── Pill — primary (light-fill) / secondary (hairline) ─────
   Equal size; hover by value, never hue. */

export function Pill({
  children,
  variant = "primary",
  href,
  onClick,
  className = "",
}: {
  children: ReactNode;
  variant?: "primary" | "secondary";
  href?: string;
  onClick?: () => void;
  className?: string;
}) {
  const base =
    "inline-flex items-center justify-center rounded-full px-4 py-2 text-[13px] font-medium whitespace-nowrap transition duration-150 ease-[var(--ease-out)] active:scale-[0.98]";
  const variantClass =
    variant === "primary"
      ? "bg-text-primary text-background hover:bg-white"
      : "border border-hairline-strong text-text-primary hover:border-text-secondary";
  const cls = `${base} ${variantClass} ${className}`;

  if (href) {
    return (
      <a href={href} className={cls}>
        {children}
      </a>
    );
  }
  return (
    <button type="button" onClick={onClick} className={cls}>
      {children}
    </button>
  );
}

/* ── WireMark — thin-gray unfilled wireframe isometric mark ──
   No fill, no shading, no pictograms. Marks drawn from
   deploy / branch / commit / CI motifs. */

export type WireMarkName = "deploy" | "branch" | "commit" | "ci";

export function WireMark({
  name,
  size = 40,
  className = "",
}: {
  name: WireMarkName;
  size?: number;
  className?: string;
}) {
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 48 48",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 1,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
  };
  return (
    <svg {...common} className={`text-text-dim ${className}`}>
      {name === "deploy" && (
        <>
          {/* stacked isometric slabs */}
          <path d="M24 6 42 16 24 26 6 16Z" />
          <path d="M6 24 24 34 42 24" />
          <path d="M6 32 24 42 42 32" />
        </>
      )}
      {name === "branch" && (
        <>
          <circle cx="14" cy="12" r="4" />
          <circle cx="14" cy="36" r="4" />
          <circle cx="34" cy="20" r="4" />
          <path d="M14 16v16" />
          <path d="M34 24c0 8-8 8-12 12" />
        </>
      )}
      {name === "commit" && (
        <>
          <circle cx="24" cy="24" r="6" />
          <path d="M6 24h12" />
          <path d="M30 24h12" />
        </>
      )}
      {name === "ci" && (
        <>
          <circle cx="24" cy="24" r="16" />
          <path d="M16 24.5 22 30 33 18" />
        </>
      )}
    </svg>
  );
}
