import { FeatureItem } from "../config/siteConfig";

type FeaturesSectionProps = {
  features: FeatureItem[];
};

export function FeaturesSection({ features }: FeaturesSectionProps) {
  return (
    <section className="grid gap-8 py-6 md:grid-cols-3">
      {features.map((feature) => (
        <article
          key={feature.title}
          className="rounded-[1.5rem] border border-slate-200 bg-white/75 p-6 shadow-sm"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.25em] text-brand">
            Feature
          </p>
          <h3 className="mt-4 text-2xl font-semibold text-slate-950">
            {feature.title}
          </h3>
          <p className="mt-3 text-base leading-7 text-slate-600">
            {feature.description}
          </p>
        </article>
      ))}
    </section>
  );
}
