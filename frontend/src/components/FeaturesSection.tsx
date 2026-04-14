import { FeatureItem } from "../config/siteConfig";
import { Reveal } from "./Reveal";

type FeaturesSectionProps = {
  features: FeatureItem[];
};

export function FeaturesSection({ features }: FeaturesSectionProps) {
  return (
    <section className="space-y-5 py-2">
      <Reveal className="max-w-2xl space-y-3">
        <p className="text-sm font-semibold uppercase tracking-[0.3em] text-brand">
          Features
        </p>
        <h2 className="text-3xl font-semibold tracking-tight text-slate-950 md:text-4xl">
          The structure stays the same while the business story and lead route
          change.
        </h2>
      </Reveal>
      <div className="grid gap-5 md:grid-cols-3">
        {features.map((feature, index) => (
          <Reveal key={feature.title} delayMs={index * 100}>
            <article className="group h-full rounded-[1.6rem] border border-slate-200/80 bg-white/80 p-6 shadow-[0_16px_50px_rgba(15,23,42,0.08)] transition duration-300 hover:-translate-y-1 hover:shadow-[0_22px_70px_rgba(15,23,42,0.12)]">
              <div className="flex items-center justify-between">
                <p className="text-sm font-semibold uppercase tracking-[0.25em] text-brand">
                  Feature {index + 1}
                </p>
                <span className="rounded-full bg-brand/10 px-3 py-1 text-xs font-semibold text-brand">
                  0{index + 1}
                </span>
              </div>
              <h3 className="mt-5 text-2xl font-semibold tracking-tight text-slate-950">
                {feature.title}
              </h3>
              <p className="mt-3 text-base leading-7 text-slate-600">
                {feature.description}
              </p>
            </article>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
