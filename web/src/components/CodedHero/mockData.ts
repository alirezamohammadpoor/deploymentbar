export type DeploymentStatus = "ready" | "building" | "error";
export type Environment = "Production" | "Preview";
export type FilterTab = "All" | "Production" | "Preview";
export type CIStatus = "passed" | "running" | "failed" | null;
export type ZoomPhase = "zooming-in" | "zoomed" | "zooming-out" | "normal";

export interface MockDeployment {
  id: string;
  project: string;
  branch: string;
  status: DeploymentStatus;
  commit: string;
  author: string;
  env: Environment;
  duration: string;
  time: string;
  ciStatus: CIStatus;
}

export const deployments: MockDeployment[] = [
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
    ciStatus: "passed",
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
    ciStatus: "running",
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
    ciStatus: "passed",
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
    ciStatus: "failed",
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
    ciStatus: "passed",
  },
];

export function filterDeployments(tab: FilterTab): MockDeployment[] {
  if (tab === "All") return deployments;
  return deployments.filter((d) => d.env === tab);
}

export function filterByProject(
  items: MockDeployment[],
  projectName: string | null
): MockDeployment[] {
  if (!projectName) return items;
  return items.filter((d) => d.project === projectName);
}

export const projectNames = [...new Set(deployments.map((d) => d.project))];
