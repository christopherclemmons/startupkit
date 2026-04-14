import { SiteConfig } from "../config/siteConfig";

type CtaSectionProps = {
  config: SiteConfig;
};

export function CtaSection({ config }: CtaSectionProps) {
  return (
    <div className="space-y-4">
      <p className="text-sm uppercase tracking-[0.3em] text-emerald-300">
        Ready to launch
      </p>
      <h2 className="text-3xl font-semibold md:text-4xl">
        Turn {config.siteName} into a branded acquisition page with a separate
        backend, separate data path, and reusable deployment pattern.
      </h2>
      <p className="text-slate-300">
        The page content, API base URL, color, images, and business identity are
        all driven by configuration so the next campaign is mostly variable
        changes, not code edits.
      </p>
    </div>
  );
}
