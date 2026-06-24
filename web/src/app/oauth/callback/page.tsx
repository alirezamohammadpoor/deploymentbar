import type { Metadata } from "next";
import { CallbackRedirect } from "./CallbackRedirect";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Connecting — Deploymentbar",
  robots: { index: false, follow: false },
};

export default async function OAuthCallbackPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const sp = await searchParams;
  const pick = (key: string) => (typeof sp[key] === "string" ? (sp[key] as string) : undefined);

  return (
    <CallbackRedirect code={pick("code")} state={pick("state")} error={pick("error")} />
  );
}
