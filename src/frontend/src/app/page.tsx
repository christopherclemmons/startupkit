import type { Metadata } from "next";
import Link from "next/link";
import { siteConfig } from "@/lib/site";

const valueProps = [
  {
    title: "Secure frontend defaults",
    description:
      "Security headers, same-origin backend proxying, locked-down framing rules, and non-indexed API routes reduce common web attack exposure from the first commit.",
  },
  {
    title: "Technical SEO built in",
    description:
      "Server-rendered pages, sitemap and robots routes, canonical metadata, structured data, and social preview assets provide a strong foundation before feature work starts.",
  },
  {
    title: "Backend-ready by design",
    description:
      "The frontend talks to your .NET API through a server-side proxy so teams can integrate auth, typed clients, and domain routes without reopening CORS or browser-origin questions.",
  },
];

const capabilities = [
  "Next.js App Router with server-first rendering and route metadata",
  "Semantic page structure that supports crawlability and assistive technology",
  "Tailwind CSS with responsive sections tuned for mobile and desktop",
  "Dynamic sitemap, robots.txt, manifest, and stable social preview metadata",
  "Same-origin API bridge prepared for .NET backend endpoints",
  "Docker-ready standalone output for predictable deployments",
  "Jest and Playwright hooks for smoke coverage and regression checks",
  "A homepage copy structure that targets product, platform, and engineering queries",
];

const implementationNotes = [
  "Use route handlers under /api/backend to centralize auth token forwarding and backend URL management.",
  "Keep product pages server-rendered where possible so search engines receive useful HTML without waiting on client hydration.",
  "Attach page-specific metadata at the route level and keep lower-value utility pages marked noindex.",
];

export const metadata: Metadata = {
  title: "Secure Next.js Starter for SEO-Driven Full-Stack Apps",
  description:
    "Terrastack combines Next.js, strong technical SEO defaults, accessible UI patterns, and a secure backend proxy so teams can ship production-ready web software faster.",
  alternates: {
    canonical: "/",
  },
};

export default function HomePage() {
  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8 lg:py-16">
      <section className="surface-panel overflow-hidden rounded-[2rem] px-6 py-10 shadow-xl shadow-cyan-950/5 sm:px-8 lg:px-12 lg:py-14">
        <div className="grid gap-10 lg:grid-cols-[1.25fr_0.75fr] lg:items-center">
          <div>
            <p className="eyebrow text-xs font-semibold uppercase">Next.js + .NET + SEO</p>
            <h1 className="mt-4 max-w-4xl text-4xl font-semibold tracking-tight text-slate-950 sm:text-5xl lg:text-6xl">
              Launch a search-friendly frontend that is secure by default and ready for your backend.
            </h1>
            <p className="mt-6 max-w-3xl text-lg leading-8 text-slate-700">
              {siteConfig.name} replaces the old client-only SPA model with a Next.js
              frontend that renders meaningful HTML on first load, ships cleaner metadata,
              and gives engineers a safer integration boundary for API traffic.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/connection"
                className="inline-flex items-center justify-center rounded-full bg-cyan-700 px-6 py-3 text-sm font-semibold text-white transition hover:bg-cyan-800"
              >
                Verify backend connection
              </Link>
              <a
                href="#capabilities"
                className="inline-flex items-center justify-center rounded-full border border-slate-300 bg-white px-6 py-3 text-sm font-semibold text-slate-900 transition hover:border-slate-400 hover:bg-slate-50"
              >
                Review the platform defaults
              </a>
            </div>
          </div>

          <aside className="rounded-[1.75rem] bg-slate-950 p-6 text-slate-100 shadow-2xl shadow-slate-950/20">
            <p className="text-xs font-semibold uppercase tracking-[0.28em] text-cyan-300">
              Technical SEO checklist
            </p>
            <ul className="mt-5 space-y-4 text-sm leading-6 text-slate-300">
              <li>Metadata, canonical URLs, robots, sitemap, and manifest routes are wired in.</li>
              <li>Open Graph and Twitter preview images are served from a stable static asset.</li>
              <li>Public pages keep semantic heading order and crawlable internal links.</li>
              <li>Backend calls stay same-origin from the browser through a server-side proxy.</li>
            </ul>
          </aside>
        </div>
      </section>

      <section className="mt-10 grid gap-6 md:grid-cols-3">
        {valueProps.map((item) => (
          <article key={item.title} className="surface-panel rounded-[1.75rem] p-6 shadow-sm">
            <h2 className="section-title text-2xl font-semibold">{item.title}</h2>
            <p className="mt-3 text-sm leading-7 text-slate-700">{item.description}</p>
          </article>
        ))}
      </section>

      <section
        id="capabilities"
        className="mt-10 grid gap-6 rounded-[2rem] bg-slate-950 px-6 py-10 text-white shadow-2xl shadow-slate-950/10 sm:px-8 lg:grid-cols-[1.1fr_0.9fr]"
      >
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.28em] text-cyan-300">
            What you get
          </p>
          <h2 className="mt-4 text-3xl font-semibold tracking-tight sm:text-4xl">
            A frontend foundation aimed at production and discoverability instead of a generic starter shell.
          </h2>
          <div className="mt-6 grid gap-3">
            {capabilities.map((capability) => (
              <div
                key={capability}
                className="rounded-2xl border border-white/10 bg-white/5 px-4 py-4 text-sm leading-6 text-slate-200"
              >
                {capability}
              </div>
            ))}
          </div>
        </div>

        <div className="space-y-6 rounded-[1.75rem] border border-white/10 bg-white/5 p-6">
          <div>
            <h3 className="text-xl font-semibold text-white">Implementation notes</h3>
            <ul className="mt-4 space-y-3 text-sm leading-6 text-slate-200">
              {implementationNotes.map((note) => (
                <li key={note}>{note}</li>
              ))}
            </ul>
          </div>
          <div className="rounded-2xl bg-cyan-400/10 p-5">
            <h3 className="text-lg font-semibold text-cyan-200">Why this matters</h3>
            <p className="mt-3 text-sm leading-6 text-cyan-50/90">
              Moving SEO and security concerns into the app foundation keeps future
              feature teams from bolting them on inconsistently. The result is less
              rework, fewer crawl issues, and a cleaner path to authenticated backend
              traffic.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
