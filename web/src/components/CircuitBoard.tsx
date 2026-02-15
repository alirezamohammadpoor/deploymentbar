"use client";

import { useRef, useEffect, useCallback } from "react";

/* ─── color constants ─── */

const BLUE_CORE = "#3b82f6";
const BLUE_GLOW = "rgba(59,130,246,0.125)"; // #3b82f620
const BLUE_GLOW_SHADOW = "rgba(59,130,246,0.5)";
const TRACE_DORMANT = "#1a1a2e";
const TRACE_DECORATIVE = "#0d0d1a";

/* ─── data model ─── */

interface Node {
  x: number;
  y: number;
  glowIntensity: number;
}

type TracePath = { x: number; y: number }[];

interface Electron {
  pathIndex: number;
  progress: number;
  speed: number;
  tailLength: number;
  burstRemaining: number;
}

/* ─── helpers ─── */

function pathLength(path: TracePath): number {
  let len = 0;
  for (let i = 1; i < path.length; i++) {
    const dx = path[i].x - path[i - 1].x;
    const dy = path[i].y - path[i - 1].y;
    len += Math.sqrt(dx * dx + dy * dy);
  }
  return len;
}

function pointAtProgress(
  path: TracePath,
  t: number
): { x: number; y: number } {
  const total = pathLength(path);
  let target = t * total;
  for (let i = 1; i < path.length; i++) {
    const dx = path[i].x - path[i - 1].x;
    const dy = path[i].y - path[i - 1].y;
    const segLen = Math.sqrt(dx * dx + dy * dy);
    if (target <= segLen || i === path.length - 1) {
      const ratio = segLen === 0 ? 0 : Math.min(target / segLen, 1);
      return {
        x: path[i - 1].x + dx * ratio,
        y: path[i - 1].y + dy * ratio,
      };
    }
    target -= segLen;
  }
  return path[path.length - 1];
}

function buildTraces(
  nodes: Node[],
  w: number,
  h: number
): { main: TracePath[]; decorative: TracePath[] } {
  const [push, build, deploy] = nodes;

  // Push → Build: centered path with vertical jog down
  const midX1 = push.x + (build.x - push.x) * 0.38;
  const jogY1 = push.y + 50;
  const trace1: TracePath = [
    { x: push.x, y: push.y },
    { x: midX1, y: push.y },
    { x: midX1, y: jogY1 },
    { x: midX1 + (build.x - midX1) * 0.5, y: jogY1 },
    { x: midX1 + (build.x - midX1) * 0.5, y: build.y },
    { x: build.x, y: build.y },
  ];

  // Build → Deploy: path with upward jog
  const midX2 = build.x + (deploy.x - build.x) * 0.42;
  const jogY2 = build.y - 45;
  const trace2: TracePath = [
    { x: build.x, y: build.y },
    { x: midX2, y: build.y },
    { x: midX2, y: jogY2 },
    { x: midX2 + (deploy.x - midX2) * 0.55, y: jogY2 },
    { x: midX2 + (deploy.x - midX2) * 0.55, y: deploy.y },
    { x: deploy.x, y: deploy.y },
  ];

  const decorative: TracePath[] = [
    // === Stubs branching off main trace 1 ===
    [
      { x: midX1, y: push.y + 15 },
      { x: midX1 - 35, y: push.y + 15 },
      { x: midX1 - 35, y: push.y + 60 },
    ],
    [
      { x: midX1 + (build.x - midX1) * 0.25, y: jogY1 },
      { x: midX1 + (build.x - midX1) * 0.25, y: jogY1 + 40 },
    ],
    [
      { x: midX1 + (build.x - midX1) * 0.5, y: jogY1 - 10 },
      { x: midX1 + (build.x - midX1) * 0.5 + 30, y: jogY1 - 10 },
    ],

    // === Stubs branching off main trace 2 ===
    [
      { x: midX2, y: build.y - 12 },
      { x: midX2 + 30, y: build.y - 12 },
      { x: midX2 + 30, y: build.y - 55 },
    ],
    [
      { x: midX2 + (deploy.x - midX2) * 0.3, y: jogY2 },
      { x: midX2 + (deploy.x - midX2) * 0.3, y: jogY2 - 35 },
    ],
    [
      { x: midX2 + (deploy.x - midX2) * 0.55, y: jogY2 + 10 },
      { x: midX2 + (deploy.x - midX2) * 0.55 - 25, y: jogY2 + 10 },
    ],

    // === Center-area dense traces (behind headline/subhead) ===
    // Horizontal runs across center
    [
      { x: w * 0.32, y: h * 0.28 },
      { x: w * 0.45, y: h * 0.28 },
      { x: w * 0.45, y: h * 0.35 },
    ],
    [
      { x: w * 0.48, y: h * 0.22 },
      { x: w * 0.62, y: h * 0.22 },
      { x: w * 0.62, y: h * 0.28 },
    ],
    [
      { x: w * 0.38, y: h * 0.33 },
      { x: w * 0.38, y: h * 0.4 },
      { x: w * 0.48, y: h * 0.4 },
    ],
    [
      { x: w * 0.52, y: h * 0.32 },
      { x: w * 0.52, y: h * 0.38 },
      { x: w * 0.6, y: h * 0.38 },
    ],
    [
      { x: w * 0.42, y: h * 0.48 },
      { x: w * 0.56, y: h * 0.48 },
    ],
    [
      { x: w * 0.35, y: h * 0.52 },
      { x: w * 0.35, y: h * 0.58 },
      { x: w * 0.42, y: h * 0.58 },
    ],
    [
      { x: w * 0.58, y: h * 0.5 },
      { x: w * 0.58, y: h * 0.57 },
      { x: w * 0.65, y: h * 0.57 },
    ],
    // Vertical stubs in center
    [
      { x: w * 0.44, y: h * 0.15 },
      { x: w * 0.44, y: h * 0.24 },
    ],
    [
      { x: w * 0.56, y: h * 0.16 },
      { x: w * 0.56, y: h * 0.22 },
    ],
    [
      { x: w * 0.5, y: h * 0.55 },
      { x: w * 0.5, y: h * 0.64 },
      { x: w * 0.46, y: h * 0.64 },
    ],

    // === Left-side traces ===
    [
      { x: push.x, y: push.y },
      { x: push.x - w * 0.06, y: push.y },
      { x: push.x - w * 0.06, y: push.y - 55 },
      { x: push.x - w * 0.12, y: push.y - 55 },
    ],
    [
      { x: push.x - w * 0.06, y: push.y - 55 },
      { x: push.x - w * 0.06, y: push.y - 90 },
    ],
    [
      { x: push.x, y: push.y + 25 },
      { x: push.x - w * 0.08, y: push.y + 25 },
      { x: push.x - w * 0.08, y: push.y + 70 },
    ],
    [
      { x: w * 0.04, y: h * 0.3 },
      { x: w * 0.04, y: h * 0.45 },
      { x: w * 0.08, y: h * 0.45 },
    ],
    [
      { x: w * 0.06, y: h * 0.55 },
      { x: w * 0.1, y: h * 0.55 },
      { x: w * 0.1, y: h * 0.65 },
    ],
    [
      { x: w * 0.18, y: h * 0.2 },
      { x: w * 0.25, y: h * 0.2 },
      { x: w * 0.25, y: h * 0.28 },
    ],
    [
      { x: w * 0.15, y: h * 0.6 },
      { x: w * 0.22, y: h * 0.6 },
      { x: w * 0.22, y: h * 0.7 },
    ],

    // === Right-side traces ===
    [
      { x: deploy.x, y: deploy.y },
      { x: deploy.x + w * 0.06, y: deploy.y },
      { x: deploy.x + w * 0.06, y: deploy.y + 50 },
      { x: deploy.x + w * 0.12, y: deploy.y + 50 },
    ],
    [
      { x: deploy.x + w * 0.06, y: deploy.y + 50 },
      { x: deploy.x + w * 0.06, y: deploy.y + 85 },
    ],
    [
      { x: deploy.x, y: deploy.y - 20 },
      { x: deploy.x + w * 0.08, y: deploy.y - 20 },
      { x: deploy.x + w * 0.08, y: deploy.y - 65 },
    ],
    [
      { x: w * 0.96, y: h * 0.35 },
      { x: w * 0.96, y: h * 0.5 },
      { x: w * 0.92, y: h * 0.5 },
    ],
    [
      { x: w * 0.94, y: h * 0.6 },
      { x: w * 0.9, y: h * 0.6 },
      { x: w * 0.9, y: h * 0.7 },
    ],
    [
      { x: w * 0.75, y: h * 0.2 },
      { x: w * 0.82, y: h * 0.2 },
      { x: w * 0.82, y: h * 0.28 },
    ],
    [
      { x: w * 0.78, y: h * 0.6 },
      { x: w * 0.85, y: h * 0.6 },
      { x: w * 0.85, y: h * 0.52 },
    ],

    // === Top-area runs ===
    [
      { x: w * 0.25, y: h * 0.12 },
      { x: w * 0.35, y: h * 0.12 },
      { x: w * 0.35, y: h * 0.18 },
    ],
    [
      { x: w * 0.65, y: h * 0.1 },
      { x: w * 0.72, y: h * 0.1 },
      { x: w * 0.72, y: h * 0.17 },
    ],

    // === Bottom-area runs ===
    [
      { x: w * 0.3, y: h * 0.78 },
      { x: w * 0.4, y: h * 0.78 },
      { x: w * 0.4, y: h * 0.85 },
    ],
    [
      { x: w * 0.55, y: h * 0.75 },
      { x: w * 0.65, y: h * 0.75 },
    ],
    [
      { x: w * 0.7, y: h * 0.78 },
      { x: w * 0.7, y: h * 0.85 },
      { x: w * 0.78, y: h * 0.85 },
    ],
  ];

  return { main: [trace1, trace2], decorative };
}

function initElectrons(): Electron[] {
  return [
    { pathIndex: 0, progress: 0.0, speed: 0.0015, tailLength: 0.14, burstRemaining: 0 },
    { pathIndex: 0, progress: 0.35, speed: 0.0018, tailLength: 0.12, burstRemaining: 0 },
    { pathIndex: 0, progress: 0.7, speed: 0.0016, tailLength: 0.13, burstRemaining: 0 },
    { pathIndex: 1, progress: 0.1, speed: 0.0017, tailLength: 0.13, burstRemaining: 0 },
    { pathIndex: 1, progress: 0.45, speed: 0.0015, tailLength: 0.14, burstRemaining: 0 },
    { pathIndex: 1, progress: 0.8, speed: 0.0018, tailLength: 0.12, burstRemaining: 0 },
  ];
}

/* ─── drawing helpers ─── */

function drawDotGrid(
  ctx: CanvasRenderingContext2D,
  w: number,
  h: number
) {
  const spacing = 24;
  const cx = w / 2;
  const cy = h / 2;
  const maxDist = Math.sqrt(cx * cx + cy * cy);

  for (let x = spacing; x < w; x += spacing) {
    for (let y = spacing; y < h; y += spacing) {
      const dx = x - cx;
      const dy = y - cy;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const fade = 1 - Math.pow(dist / maxDist, 1.5);
      const alpha = 0.04 * Math.max(fade, 0);
      if (alpha < 0.003) continue;

      ctx.beginPath();
      ctx.arc(x, y, 0.8, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(255,255,255,${alpha})`;
      ctx.fill();
    }
  }
}

function drawTracePath(
  ctx: CanvasRenderingContext2D,
  path: TracePath,
  color: string,
  width: number
) {
  if (path.length < 2) return;
  ctx.beginPath();
  ctx.moveTo(path[0].x, path[0].y);
  for (let i = 1; i < path.length; i++) {
    ctx.lineTo(path[i].x, path[i].y);
  }
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.stroke();
}

function drawJunctionDots(ctx: CanvasRenderingContext2D, path: TracePath, size: number) {
  for (let i = 1; i < path.length - 1; i++) {
    ctx.beginPath();
    ctx.arc(path[i].x, path[i].y, size, 0, Math.PI * 2);
    ctx.fillStyle = TRACE_DORMANT;
    ctx.fill();
  }
}

function drawIlluminatedSegment(
  ctx: CanvasRenderingContext2D,
  path: TracePath,
  electronProgress: number,
  tailLength: number
) {
  if (electronProgress < 0) return;
  const total = pathLength(path);
  const headDist = electronProgress * total;
  const tailDist = Math.max(0, (electronProgress - tailLength) * total);

  const steps = 24;
  for (let s = 0; s < steps; s++) {
    const t0 = tailDist + ((headDist - tailDist) * s) / steps;
    const t1 = tailDist + ((headDist - tailDist) * (s + 1)) / steps;
    const p0 = pointAtProgress(path, t0 / total);
    const p1 = pointAtProgress(path, t1 / total);
    const alpha = ((s + 1) / steps) * 0.7;

    ctx.beginPath();
    ctx.moveTo(p0.x, p0.y);
    ctx.lineTo(p1.x, p1.y);
    ctx.strokeStyle = `rgba(59,130,246,${alpha})`;
    ctx.lineWidth = 2.5;
    ctx.lineCap = "round";
    ctx.stroke();
  }
}

function drawElectron(
  ctx: CanvasRenderingContext2D,
  path: TracePath,
  progress: number
) {
  if (progress < 0) return;
  const pos = pointAtProgress(path, progress);

  ctx.save();
  ctx.shadowColor = BLUE_GLOW_SHADOW;
  ctx.shadowBlur = 12;
  ctx.beginPath();
  ctx.arc(pos.x, pos.y, 3, 0, Math.PI * 2);
  ctx.fillStyle = BLUE_CORE;
  ctx.fill();
  ctx.restore();
}

function drawNode(
  ctx: CanvasRenderingContext2D,
  node: Node
) {
  const size = 64;
  const half = size / 2;
  const r = 10;
  const x = node.x - half;
  const y = node.y - half;
  const intensity = node.glowIntensity;

  // Glow behind node
  if (intensity > 0.01) {
    const glowRadius = 45 + intensity * 30;
    const grad = ctx.createRadialGradient(
      node.x, node.y, 0,
      node.x, node.y, glowRadius
    );
    grad.addColorStop(0, `rgba(59,130,246,${intensity * 0.2})`);
    grad.addColorStop(1, "rgba(59,130,246,0)");
    ctx.fillStyle = grad;
    ctx.fillRect(
      node.x - glowRadius,
      node.y - glowRadius,
      glowRadius * 2,
      glowRadius * 2
    );
  }

  // Rounded rect
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + size - r, y);
  ctx.arcTo(x + size, y, x + size, y + r, r);
  ctx.lineTo(x + size, y + size - r);
  ctx.arcTo(x + size, y + size, x + size - r, y + size, r);
  ctx.lineTo(x + r, y + size);
  ctx.arcTo(x, y + size, x, y + size - r, r);
  ctx.lineTo(x, y + r);
  ctx.arcTo(x, y, x + r, y, r);
  ctx.closePath();

  ctx.fillStyle = `rgba(59,130,246,${intensity * 0.06})`;
  ctx.fill();

  // Interpolate border: #222 dormant → #3b82f6 active
  const borderR = Math.round(0x22 + (0x3b - 0x22) * intensity);
  const borderG = Math.round(0x22 + (0x82 - 0x22) * intensity);
  const borderB = Math.round(0x22 + (0xf6 - 0x22) * intensity);
  ctx.strokeStyle = `rgb(${borderR},${borderG},${borderB})`;
  ctx.lineWidth = 1.5;
  ctx.stroke();
}

/* ─── component ─── */

export function CircuitBoard({ className }: { className?: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const stateRef = useRef<{
    nodes: Node[];
    electrons: Electron[];
    main: TracePath[];
    decorative: TracePath[];
  } | null>(null);

  const computeLayout = useCallback((w: number, h: number) => {
    const cy = h * 0.42;
    // Nodes centered: 30%–50%–70% instead of 20%–50%–80%
    const nodes: Node[] = [
      { x: w * 0.3, y: cy, glowIntensity: 0 },
      { x: w * 0.5, y: cy, glowIntensity: 0 },
      { x: w * 0.7, y: cy, glowIntensity: 0 },
    ];
    const { main, decorative } = buildTraces(nodes, w, h);

    if (stateRef.current) {
      stateRef.current.nodes = nodes;
      stateRef.current.main = main;
      stateRef.current.decorative = decorative;
    } else {
      stateRef.current = {
        nodes,
        electrons: initElectrons(),
        main,
        decorative,
      };
    }
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let rafId: number;

    function resize() {
      const dpr = window.devicePixelRatio || 1;
      const rect = container!.getBoundingClientRect();
      const w = rect.width;
      const h = rect.height;

      canvas!.width = w * dpr;
      canvas!.height = h * dpr;
      canvas!.style.width = `${w}px`;
      canvas!.style.height = `${h}px`;
      ctx!.setTransform(dpr, 0, 0, dpr, 0, 0);

      computeLayout(w, h);
    }

    resize();

    const ro = new ResizeObserver(resize);
    ro.observe(container);

    function checkNodeGlow(electron: Electron, nodes: Node[]) {
      if (electron.pathIndex === 0) {
        if (electron.progress > -0.01 && electron.progress < 0.05)
          nodes[0].glowIntensity = Math.max(nodes[0].glowIntensity, 0.8);
        if (electron.progress > 0.95)
          nodes[1].glowIntensity = Math.max(nodes[1].glowIntensity, 1.0);
      } else {
        if (electron.progress > -0.01 && electron.progress < 0.05)
          nodes[1].glowIntensity = Math.max(nodes[1].glowIntensity, 0.8);
        if (electron.progress > 0.95)
          nodes[2].glowIntensity = Math.max(nodes[2].glowIntensity, 1.0);
      }
    }

    function frame() {
      const state = stateRef.current;
      if (!state) {
        rafId = requestAnimationFrame(frame);
        return;
      }

      const w = canvas!.width / (window.devicePixelRatio || 1);
      const h = canvas!.height / (window.devicePixelRatio || 1);

      ctx!.clearRect(0, 0, w, h);

      // 1. Dot grid substrate
      drawDotGrid(ctx!, w, h);

      // 2. Decorative traces
      for (const dt of state.decorative) {
        drawTracePath(ctx!, dt, TRACE_DECORATIVE, 1);
        drawJunctionDots(ctx!, dt, 1.5);
      }

      // 3. Main traces + junction dots
      for (const mt of state.main) {
        drawTracePath(ctx!, mt, TRACE_DORMANT, 2);
        drawJunctionDots(ctx!, mt, 2.5);
      }

      // 4. Illuminated segments + electrons
      for (const e of state.electrons) {
        const path = state.main[e.pathIndex];
        if (!path) continue;

        drawIlluminatedSegment(ctx!, path, e.progress, e.tailLength);
        drawElectron(ctx!, path, e.progress);
        checkNodeGlow(e, state.nodes);

        // Update electron position
        let speed = e.speed;
        if (e.burstRemaining > 0) {
          speed *= 2;
          e.burstRemaining -= speed;
        } else if (Math.random() < 0.002) {
          e.burstRemaining = 0.15 + Math.random() * 0.05;
        }
        e.progress += speed;

        if (e.progress >= 1.0) {
          e.progress = -(Math.random() * 0.08);
        }
      }

      // 5. Node shapes
      for (const node of state.nodes) {
        drawNode(ctx!, node);
        node.glowIntensity *= 0.97;
        if (node.glowIntensity < 0.005) node.glowIntensity = 0;
      }

      rafId = requestAnimationFrame(frame);
    }

    rafId = requestAnimationFrame(frame);

    return () => {
      cancelAnimationFrame(rafId);
      ro.disconnect();
    };
  }, [computeLayout]);

  return (
    <div
      ref={containerRef}
      className={className ?? "relative w-full h-[300px]"}
      style={{ overflow: "hidden" }}
    >
      <canvas
        ref={canvasRef}
        style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}
      />
    </div>
  );
}
