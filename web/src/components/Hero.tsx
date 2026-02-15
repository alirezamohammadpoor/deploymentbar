"use client";

import type { CSSProperties } from "react";
import { CodedHero } from "./CodedHero/CodedHero";
import { StreamingGrid } from "./StreamingGrid";

const abs: CSSProperties = { position: "absolute", pointerEvents: "none" };

function GradientGlow() {
  return (
    <div
      style={{
        ...abs,
        inset: 0,
        background:
          "linear-gradient(to bottom, transparent 30%, rgba(0, 112, 243, 0.08) 60%, rgba(0, 112, 243, 0.18) 100%)",
        zIndex: 0,
      }}
    />
  );
}

export function Hero() {
  return (
    <section className="relative flex flex-col items-center overflow-hidden px-6 pt-36 pb-16 text-center">
      <StreamingGrid className="absolute inset-0 w-full h-full pointer-events-none" />
      <GradientGlow />
      <CodedHero />
    </section>
  );
}
