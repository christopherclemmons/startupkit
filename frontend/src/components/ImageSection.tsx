import { SiteConfig } from "../config/siteConfig";
import { Reveal } from "./Reveal";

type ImageSectionProps = {
  config: SiteConfig;
};

export function ImageSection({ config }: ImageSectionProps) {
  return (
    <section className="grid gap-6 py-4 md:grid-cols-[0.9fr_1.1fr] md:items-center md:py-6">
      <Reveal className="space-y-5">
        <p className="text-sm font-semibold uppercase tracking-[0.3em] text-brand">
          Message-market fit
        </p>
        <h2 className="max-w-xl text-3xl font-semibold tracking-tight text-slate-950 md:text-4xl">
          Reuse one stack, swap the brand story, and measure demand with a real
          backend.
        </h2>
        <p className="max-w-xl text-base leading-8 text-slate-600 md:text-lg">
          Each deployment can carry its own business name, subdomain, imagery,
          API endpoint, and lead tagging context without changing the component
          code.
        </p>
        <div className="grid gap-3 pt-2 sm:grid-cols-2">
          {[
            "Separate branding per deployment",
            "Independent lead destination and storage",
            "No browser-to-DynamoDB access",
            "Fast duplication for the next campaign",
          ].map((item) => (
            <div
              key={item}
              className="rounded-2xl border border-slate-200/80 bg-white/80 px-4 py-4 text-sm font-medium text-slate-700 shadow-sm"
            >
              {item}
            </div>
          ))}
        </div>
      </Reveal>

      <Reveal className="overflow-hidden rounded-[2rem] border border-slate-200/80 bg-white shadow-[0_18px_55px_rgba(15,23,42,0.1)]">
        <div className="relative">
          <img
            alt={`${config.siteName} supporting section`}
            className="h-full min-h-[320px] w-full object-cover"
            src={config.sectionImageUrl}
          />
          <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(15,23,42,0.06),rgba(15,23,42,0.5))]" />
          <div className="absolute bottom-4 left-4 right-4 grid gap-3 rounded-[1.35rem] border border-white/15 bg-slate-950/55 p-4 text-white backdrop-blur md:grid-cols-3">
            {[
              { label: "Brand", value: config.siteName },
              { label: "Environment", value: config.envName },
              { label: "CTA", value: config.ctaText },
            ].map((item) => (
              <div key={item.label}>
                <p className="text-xs uppercase tracking-[0.28em] text-slate-300">
                  {item.label}
                </p>
                <p className="mt-1 text-sm font-semibold">{item.value}</p>
              </div>
            ))}
          </div>
        </div>
      </Reveal>
    </section>
  );
}
