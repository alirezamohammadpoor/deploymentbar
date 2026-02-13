"use client";

import { useDeployAnimation } from "../hooks/useDeployAnimation";

/* ── DeployButton ────────────────────────────────────────── */

function DeployButton({ phase, onClick }: { phase: string; onClick: () => void }) {
  const isIdle = phase === "idle";

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={!isIdle}
      className={`
        inline-flex items-center justify-center gap-2 rounded-lg px-6 py-3 text-sm font-medium
        transition-all duration-200
        ${isIdle
          ? "bg-white text-black hover:-translate-y-0.5 hover:shadow-lg hover:shadow-white/10 cursor-pointer"
          : "bg-[#1a1a1a] text-[#666] cursor-not-allowed"
        }
      `}
    >
      <span className={isIdle ? "" : "animate-spin-slow inline-block"}>
        ▲
      </span>
      {isIdle ? "Deploy" : "Deploying..."}
    </button>
  );
}

/* ── InteractiveHero (exported) ──────────────────────────── */

export function InteractiveHero() {
  const { phase, deploy } = useDeployAnimation();

  const handleDeploy = () => {
    deploy();
    window.dispatchEvent(new CustomEvent("deploybar-deploy"));
  };

  return (
    <div className="relative z-10 mx-auto flex w-full max-w-md flex-col items-center text-center">
      {/* Headline */}
      <h1 className="hero-enter text-4xl font-medium leading-tight tracking-tight text-text-primary sm:text-5xl">
        Your deployments.{" "}
        <span className="text-accent-blue">Always visible.</span>
      </h1>

      {/* Subheadline */}
      <p className="hero-enter-delay-1 mt-6 text-base leading-relaxed text-text-secondary">
        Native macOS monitoring for every Vercel deployment.
      </p>

      {/* Deploy button */}
      <div className="hero-enter-delay-2 mt-10">
        <DeployButton phase={phase} onClick={handleDeploy} />
      </div>

      {/* Helper text */}
      <p className="hero-enter-delay-3 mt-4 text-xs text-text-secondary/50">
        Free during beta &middot; macOS 14+ required
      </p>
    </div>
  );
}
