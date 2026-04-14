import { SiteConfig } from "../config/siteConfig";
import { Reveal } from "./Reveal";

type HeroSectionProps = {
  config: SiteConfig;
};

export function HeroSection({ config }: HeroSectionProps) {
  return (
    <section className="grid gap-6 rounded-[2.25rem] border border-white/70 bg-white/85 p-5 shadow-[0_24px_80px_rgba(15,23,42,0.12)] backdrop-blur md:grid-cols-[1.08fr_0.92fr] md:p-6">
      <Reveal className="space-y-6 rounded-[1.75rem] bg-[linear-gradient(180deg,rgba(255,255,255,0.95),rgba(255,255,255,0.78))] p-6 md:p-8">
        <span className="inline-flex w-fit items-center gap-2 rounded-full border border-brand/15 bg-brand/5 px-4 py-2 text-sm font-semibold text-brand">
          <span className="h-2 w-2 rounded-full bg-brand" />
          {config.siteName} | {config.envName}
        </span>
        <div className="space-y-5">
          <h1 className="max-w-3xl text-4xl font-semibold tracking-tight text-slate-950 md:text-6xl md:leading-[1.02]">
            {config.heroTitle}
          </h1>
          <p className="max-w-2xl text-lg leading-8 text-slate-600 md:text-xl">
            {config.heroSubtitle}
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <a
            className="inline-flex items-center justify-center rounded-full bg-brand px-6 py-3 font-semibold text-white shadow-lg shadow-brand/20 transition duration-200 hover:-translate-y-0.5 hover:opacity-95"
            href="#lead-form"
          >
            {config.ctaText}
          </a>
          <span className="inline-flex items-center rounded-full border border-slate-200 bg-white/90 px-5 py-3 text-sm text-slate-600">
            No nav, no friction, just campaign signal
          </span>
        </div>
        <div className="grid gap-3 pt-2 sm:grid-cols-3">
          {[
            "Brand-specific subdomain",
            "Tagged lead storage path",
            "Reusable config-driven copy",
          ].map((value) => (
            <div
              key={value}
              className="rounded-2xl border border-slate-200/80 bg-white/80 px-4 py-3 text-sm font-medium text-slate-700 shadow-sm"
            >
              {value}
            </div>
          ))}
        </div>
      </Reveal>

      <Reveal className="overflow-hidden rounded-[1.75rem] border border-slate-200 bg-slate-950 shadow-2xl shadow-slate-950/20">
        <div className="relative h-full min-h-[360px]">
          <img
            alt={`${config.siteName} campaign hero`}
            className="h-full min-h-[360px] w-full object-cover"
            src={config.heroImageUrl}
          />
          <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(15,23,42,0.08),rgba(15,23,42,0.65))]" />
          <div className="absolute left-5 top-5 rounded-full border border-white/20 bg-slate-950/55 px-4 py-2 text-xs font-semibold uppercase tracking-[0.3em] text-white backdrop-blur">
            Live campaign
          </div>
          <div className="absolute bottom-5 left-5 right-5 rounded-[1.25rem] border border-white/15 bg-white/10 p-4 text-white backdrop-blur-md">
            <p className="text-sm uppercase tracking-[0.28em] text-amber-100">
              Deployment snapshot
            </p>
            <p className="mt-2 text-lg font-medium leading-7">
              Every campaign keeps its own visual identity, lead destination,
              and infrastructure context.
            </p>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
