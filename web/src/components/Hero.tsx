"use client";

import type { CSSProperties } from "react";
import { HeroShowcase } from "./HeroShowcase";

const B = "0, 112, 243";

const abs: CSSProperties = { position: "absolute", pointerEvents: "none" };

function Stars() {
  return (
    <div
      className="hero-stars"
      style={{ ...abs, inset: 0, zIndex: 0 }}
    />
  );
}

function Background() {
  return (
    <>
      <Stars />
      <div
        className="hero-glow-pulse"
        style={{
          ...abs,
          top: "38%",
          left: "50%",
          width: "60vw",
          height: "60vh",
          background: `radial-gradient(ellipse at center, rgba(${B}, 0.4) 0%, rgba(${B}, 0.15) 35%, rgba(${B}, 0.04) 60%, transparent 75%)`,
          filter: "blur(100px)",
          zIndex: 0,
        }}
      />
    </>
  );
}

export function Hero() {
  return (
    <section className="relative flex flex-col items-center overflow-hidden px-6 pt-36 pb-16 text-center">
      <Background />
      <HeroShowcase />
    </section>
  );
}
