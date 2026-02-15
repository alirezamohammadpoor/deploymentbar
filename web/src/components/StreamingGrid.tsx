"use client";

import { useId } from "react";

const GRID = 48;
const VW = 1440;
const VH = 900;
const g = (n: number) => n * GRID;

/**
 * 3 pulse paths that travel along existing grid lines.
 * They connect near the edges of the interactive section
 * (centered ~272–1168px, lower portion of hero).
 */
const pulses = [
  // Comes from left edge, runs across the top of the interactive area, exits right
  {
    d: `M0 ${g(11)} H${g(5)} V${g(12)} H${g(25)} V${g(11)} H${VW}`,
    delay: "0s",
    dur: "12s",
  },
  // Comes from right edge, traces under the interactive area, exits left
  {
    d: `M${VW} ${g(17)} H${g(24)} V${g(16)} H${g(6)} V${g(17)} H0`,
    delay: "8s",
    dur: "12s",
  },
  // Enters top-left, winds down to bottom-right — connects top and bottom
  {
    d: `M0 ${g(4)} H${g(6)} V${g(8)} H${g(12)} V${g(14)} H${g(20)} V${g(18)} H${VW}`,
    delay: "16s",
    dur: "14.5s",
  },
];

export function StreamingGrid({ className }: { className?: string }) {
  const id = useId();

  return (
    <div
      className={className ?? "relative w-full h-full"}
      style={{ overflow: "hidden" }}
    >
      {/* Solid grid background */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: `
            linear-gradient(to right, rgba(255,255,255,0.04) 1px, transparent 1px),
            linear-gradient(to bottom, rgba(255,255,255,0.04) 1px, transparent 1px)
          `,
          backgroundSize: `${GRID}px ${GRID}px`,
          maskImage:
            "radial-gradient(ellipse 70% 50% at 50% 40%, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.15) 60%, transparent 90%)",
          WebkitMaskImage:
            "radial-gradient(ellipse 70% 50% at 50% 40%, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.15) 60%, transparent 90%)",
        }}
      />

      {/* Animated pulses — travel along grid lines, no extra static traces */}
      <svg
        style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}
        viewBox={`0 0 ${VW} ${VH}`}
        preserveAspectRatio="xMidYMid slice"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          {pulses.map((_, i) => (
            <linearGradient
              key={`g-${i}`}
              id={`${id}-g${i}`}
              gradientUnits="userSpaceOnUse"
            >
              <stop offset="0" stopColor="#3291FF" stopOpacity="0" />
              <stop offset="0.4" stopColor="#3291FF" stopOpacity="0.8" />
              <stop offset="0.5" stopColor="#5AB0FF" />
              <stop offset="0.6" stopColor="#3291FF" stopOpacity="0.8" />
              <stop offset="1" stopColor="#61DAFB" stopOpacity="0" />
            </linearGradient>
          ))}
        </defs>

        {pulses.map((p, i) => (
          <path
            key={`p-${i}`}
            d={p.d}
            fill="none"
            stroke={`url(#${id}-g${i})`}
            strokeWidth="2"
            strokeLinecap="square"
            strokeLinejoin="miter"
            className="streaming-pulse"
            style={{
              animationDuration: p.dur,
              animationDelay: p.delay,
            }}
          />
        ))}
      </svg>
    </div>
  );
}
