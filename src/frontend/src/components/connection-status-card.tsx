"use client";

import { useEffect, useState } from "react";

type HealthState = "loading" | "healthy" | "unreachable";

type HealthResponse = {
  message: string;
  state: HealthState;
  checkedAt?: string;
};

const statusCopy: Record<HealthState, { label: string; tone: string }> = {
  loading: {
    label: "Checking backend health",
    tone: "border-amber-200 bg-amber-50 text-amber-900",
  },
  healthy: {
    label: "Backend responded successfully",
    tone: "border-emerald-200 bg-emerald-50 text-emerald-900",
  },
  unreachable: {
    label: "Backend is unavailable or rejected the request",
    tone: "border-rose-200 bg-rose-50 text-rose-900",
  },
};

export function ConnectionStatusCard() {
  const [health, setHealth] = useState<HealthResponse>({
    message: "Waiting for response from the application backend.",
    state: "loading",
  });

  useEffect(() => {
    const abortController = new AbortController();

    async function loadHealth() {
      try {
        const response = await fetch("/api/backend/api/profile/health", {
          cache: "no-store",
          signal: abortController.signal,
        });

        if (!response.ok) {
          throw new Error(`Backend health check returned ${response.status}.`);
        }

        const message = await response.text();

        setHealth({
          message,
          state: "healthy",
          checkedAt: new Date().toLocaleString(),
        });
      } catch (error) {
        if (abortController.signal.aborted) {
          return;
        }

        const message =
          error instanceof Error
            ? error.message
            : "The frontend could not reach the backend health endpoint.";

        setHealth({
          message,
          state: "unreachable",
          checkedAt: new Date().toLocaleString(),
        });
      }
    }

    void loadHealth();

    return () => abortController.abort();
  }, []);

  const visualState = statusCopy[health.state];

  return (
    <section
      aria-live="polite"
      className={`rounded-3xl border p-6 shadow-sm ${visualState.tone}`}
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.24em]">Proxy status</p>
          <h2 className="mt-2 text-2xl font-semibold">{visualState.label}</h2>
        </div>
        <div className="inline-flex h-14 w-14 items-center justify-center rounded-full border border-current/20 bg-white/50 text-2xl">
          {health.state === "healthy" ? "OK" : health.state === "loading" ? "..." : "!"}
        </div>
      </div>

      <p className="mt-4 text-sm leading-6">{health.message}</p>
      <p className="mt-3 text-xs uppercase tracking-[0.24em] text-current/80">
        {health.checkedAt ? `Last checked ${health.checkedAt}` : "Request in progress"}
      </p>
    </section>
  );
}
