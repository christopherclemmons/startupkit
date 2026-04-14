import { SiteConfig } from "../config/siteConfig";

type HeroSectionProps = {
  config: SiteConfig;
};

export function HeroSection({ config }: HeroSectionProps) {
  return (
    <section className="grid gap-10 rounded-[2rem] border border-white/70 bg-white/85 px-8 py-12 shadow-xl shadow-slate-200/60 backdrop-blur md:grid-cols-[1.15fr_0.85fr] md:px-12">
      <div className="space-y-6">
        <span className="inline-flex rounded-full px-4 py-2 text-sm font-semibold text-brand ring-1 ring-brand/20">
          {config.siteName} | {config.envName}
        </span>
        <div className="space-y-4">
          <h1 className="max-w-3xl text-4xl font-semibold tracking-tight text-slate-950 md:text-6xl">
            {config.heroTitle}
          </h1>
          <p className="max-w-2xl text-lg leading-8 text-slate-600">
            {config.heroSubtitle}
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <a
            className="rounded-full bg-brand px-6 py-3 font-medium text-white transition hover:opacity-90"
            href="#lead-form"
          >
            {config.ctaText}
          </a>
          <span className="rounded-full border border-slate-200 px-6 py-3 text-sm text-slate-600">
            Built for fast validation campaigns
          </span>
        </div>
      </div>

      <div className="overflow-hidden rounded-[1.75rem] bg-slate-950">
        <img
          alt={`${config.siteName} campaign hero`}
          className="h-full min-h-[320px] w-full object-cover"
          src={config.heroImageUrl}
        />
      </div>
    </section>
  );
}
