import type { Metadata } from "next";
import { ConnectionStatusCard } from "@/components/connection-status-card";

export const metadata: Metadata = {
  title: "Backend Connection Check",
  description:
    "Validate the same-origin backend proxy and confirm the frontend can reach the API health endpoint.",
  alternates: {
    canonical: "/connection",
  },
  robots: {
    index: false,
    follow: false,
  },
};

export default function ConnectionPage() {
  return (
    <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8 lg:py-16">
      <section className="surface-panel rounded-[2rem] p-8 shadow-xl shadow-cyan-950/5">
        <p className="eyebrow text-xs font-semibold uppercase">Backend integration</p>
        <h1 className="mt-4 text-4xl font-semibold tracking-tight text-slate-950">
          Check the frontend-to-backend bridge.
        </h1>
        <p className="mt-4 max-w-3xl text-base leading-7 text-slate-700">
          This page uses the internal Next.js proxy route instead of calling the backend
          directly from the browser. That keeps the backend origin on the server side and
          gives you one place to add token forwarding, request shaping, and audit controls.
        </p>
      </section>

      <div className="mt-8">
        <ConnectionStatusCard />
      </div>
    </div>
  );
}
