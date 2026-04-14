import { SiteConfig } from "../config/siteConfig";

type ImageSectionProps = {
  config: SiteConfig;
};

export function ImageSection({ config }: ImageSectionProps) {
  return (
    <section className="grid gap-8 py-16 md:grid-cols-[0.9fr_1.1fr] md:items-center">
      <div className="space-y-4">
        <p className="text-sm font-semibold uppercase tracking-[0.25em] text-brand">
          Message-market fit
        </p>
        <h2 className="text-3xl font-semibold tracking-tight text-slate-950 md:text-4xl">
          Reuse one stack, swap the brand story, and measure demand with a real
          backend.
        </h2>
        <p className="max-w-xl text-base leading-8 text-slate-600">
          Each deployment can carry its own business name, subdomain, imagery,
          API endpoint, and lead tagging context without changing the component
          code.
        </p>
      </div>

      <div className="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
        <img
          alt={`${config.siteName} supporting section`}
          className="h-full min-h-[280px] w-full object-cover"
          src={config.sectionImageUrl}
        />
      </div>
    </section>
  );
}
