import { SiteContent } from "../config/siteConfig";
import { Reveal } from "./Reveal";

export function ImageSection({ content }: { content: SiteContent }) {
  return (
    <section className="grid gap-6 py-4 md:grid-cols-[0.9fr_1.1fr] md:items-center md:py-6">
      <Reveal className="space-y-5">
        <p className="text-sm font-semibold uppercase tracking-[0.3em] text-brand">
          Per-site isolation
        </p>
        <h2 className="max-w-xl text-3xl font-semibold tracking-tight text-slate-950 md:text-4xl">
          Each landing page has its own content document, admin login, and lead
          trail.
        </h2>
        <p className="max-w-xl text-base leading-8 text-slate-600 md:text-lg">
          You can reuse one repository while keeping business-specific copy,
          questions, branding, and submissions separated by environment and site.
        </p>
        <div className="grid gap-3 pt-2 sm:grid-cols-2">
          {[
            "Separate content JSON per deployment",
            "Admin login only for that site",
            "Lead tagging by environment and source",
            "No direct DynamoDB access from the browser",
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
            alt={`${content.site_name} supporting section`}
            className="h-full min-h-[320px] w-full object-cover"
            src={content.section_image_url}
          />
          <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(15,23,42,0.06),rgba(15,23,42,0.5))]" />
          <div className="absolute bottom-4 left-4 right-4 grid gap-3 rounded-[1.35rem] border border-white/15 bg-slate-950/55 p-4 text-white backdrop-blur md:grid-cols-3">
            {[
              { label: "Brand", value: content.site_name },
              { label: "Environment", value: content.env_name },
              { label: "Source", value: content.source_site },
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
