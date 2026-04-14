import { SiteConfig } from "../config/siteConfig";
import { Reveal } from "./Reveal";

type CtaSectionProps = {
  config: SiteConfig;
};

export function CtaSection({ config }: CtaSectionProps) {
  return (
    <Reveal className="space-y-4">
      <p className="text-sm uppercase tracking-[0.3em] text-emerald-300">
        Ready to launch
      </p>
      <h2 className="max-w-xl text-3xl font-semibold tracking-tight md:text-4xl">
        Turn {config.siteName} into a branded acquisition page with a separate
        backend, separate data path, and reusable deployment pattern.
      </h2>
      <p className="max-w-xl text-slate-300">
        The page content, API base URL, color, images, and business identity are
        all driven by configuration so the next campaign is mostly variable
        changes, not code edits.
      </p>
      <div className="grid gap-3 pt-4 sm:grid-cols-3">
        {[
          "Fast launch",
          "Config-first branding",
          "Tagged lead capture",
        ].map((item) => (
          <div
            key={item}
            className="rounded-2xl border border-white/10 bg-white/5 px-4 py-4 text-sm text-slate-100"
          >
            {item}
          </div>
        ))}
      </div>
    </Reveal>
  );
}
