"use client";

import { useEffect, useState } from "react";

type Props = {
  code?: string;
  state?: string;
  error?: string;
};

export function CallbackRedirect({ code, state, error }: Props) {
  const [deepLink, setDeepLink] = useState<string | null>(null);
  const [failure, setFailure] = useState<string | null>(null);

  useEffect(() => {
    if (error) {
      setFailure(
        error === "access_denied"
          ? "You declined the authorization."
          : `Vercel returned an error: ${error}.`,
      );
      return;
    }
    if (!code || !state) {
      setFailure("Missing authorization details — start sign-in again from the app.");
      return;
    }
    const url = `vercelbar://callback?code=${encodeURIComponent(code)}&state=${encodeURIComponent(state)}`;
    setDeepLink(url);
    // Hand the code back to the desktop app.
    window.location.href = url;
  }, [code, state, error]);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-[var(--background)] px-6 text-center">
      <div className="flex flex-col items-center gap-5">
        <svg width="34" height="30" viewBox="0 0 34 30" aria-hidden="true">
          <path d="M17 0 L34 30 L0 30 Z" fill="var(--text-primary)" />
        </svg>

        {failure ? (
          <>
            <h1 className="text-lg font-medium text-[var(--text-primary)]">
              Sign-in didn’t complete
            </h1>
            <p className="max-w-sm text-sm text-[var(--text-dim)]">{failure}</p>
          </>
        ) : (
          <>
            <h1 className="text-lg font-medium text-[var(--text-primary)]">
              Returning to Deploymentbar…
            </h1>
            <p className="max-w-sm text-sm text-[var(--text-dim)]">
              Your browser should hand you back to the app. If it doesn’t, use the button below.
            </p>
            {deepLink && (
              <a
                href={deepLink}
                className="mt-1 rounded-full bg-white px-5 py-2 text-sm font-medium text-black transition-colors hover:bg-white/90"
              >
                Open Deploymentbar
              </a>
            )}
            <p className="text-xs text-[var(--text-dim)]">You can close this tab.</p>
          </>
        )}
      </div>
    </main>
  );
}
