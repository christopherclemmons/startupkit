import { SiteContent } from "../config/siteConfig";
import { Reveal } from "./Reveal";

export function CtaSection({ content }: { content: SiteContent }) {
  return (
    <Reveal className="space-y-4">
      <p className="text-sm uppercase tracking-[0.3em] text-emerald-300">
        Ready to capture signal
      </p>
      <h2 className="max-w-xl text-3xl font-semibold tracking-tight md:text-4xl">
        {content.site_name} runs on an isolated content record and backend path.
      </h2>
      <p className="max-w-xl text-slate-300">
        Leads and content changes are tagged with this site’s environment and
        source context so Business A and Business B never share content.
      </p>
      <div className="grid gap-3 pt-4 sm:grid-cols-3">
        {["Single-site content JSON", "Protected admin editing", "Tagged lead capture"].map(
          (item) => (
            <div
              key={item}
              className="rounded-2xl border border-white/10 bg-white/5 px-4 py-4 text-sm text-slate-100"
            >
              {item}
            </div>
          ),
        )}
      </div>
    </Reveal>
  );
}
