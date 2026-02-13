"use client";

import { useState, type FormEvent } from "react";

type Status = "idle" | "loading" | "success" | "error";

export function WaitlistForm({ id }: { id?: string }) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [errorMsg, setErrorMsg] = useState("");

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setStatus("loading");
    setErrorMsg("");

    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Something went wrong");
      }

      setStatus("success");
      setEmail("");
    } catch (err) {
      setStatus("error");
      setErrorMsg(err instanceof Error ? err.message : "Something went wrong");
    }
  }

  if (status === "success") {
    return (
      <p className="text-status-ready font-medium text-base" id={id}>
        You&apos;re on the list!
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex gap-3 w-full max-w-md" id={id}>
      <input
        type="email"
        required
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="you@company.com"
        className="flex-1 rounded-lg bg-card-bg border border-card-border px-4 py-3 text-sm text-text-primary placeholder:text-text-secondary/50 focus:outline-none focus:border-accent-blue transition-colors"
      />
      <button
        type="submit"
        disabled={status === "loading"}
        className="rounded-lg bg-accent-blue px-6 py-3 text-sm font-medium text-white hover:bg-accent-blue/90 transition-colors disabled:opacity-50 whitespace-nowrap cursor-pointer"
      >
        {status === "loading" ? "Joining..." : "Join Waitlist"}
      </button>
      {status === "error" && (
        <p className="text-status-error text-sm mt-2 absolute">{errorMsg}</p>
      )}
    </form>
  );
}
