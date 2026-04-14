import { useState } from "react";
import { SiteFaq } from "../config/siteConfig";
import { Reveal } from "./Reveal";

export function FaqSection({ items }: { items: SiteFaq[] }) {
  const [openIndex, setOpenIndex] = useState(0);

  return (
    <section className="grid gap-8 rounded-[2rem] border border-white/60 bg-slate-950/95 px-6 py-10 text-white shadow-2xl shadow-slate-950/20 md:grid-cols-[0.9fr_1.1fr] md:px-10">
      <Reveal className="space-y-4">
        <p className="text-sm font-semibold uppercase tracking-[0.3em] text-amber-200">
          Questions
        </p>
        <h2 className="max-w-xl text-3xl font-semibold tracking-tight md:text-4xl">
          These questions belong to this landing page only.
        </h2>
        <p className="max-w-lg text-base leading-8 text-slate-300">
          Update them from the hidden admin route and save the same DTO back to
          DynamoDB for the current site.
        </p>
      </Reveal>

      <div className="space-y-4">
        {items.map((item, index) => {
          const isOpen = index === openIndex;

          return (
            <Reveal key={item.id} delayMs={index * 90}>
              <div className="rounded-[1.35rem] border border-white/10 bg-white/5 px-5 py-4 backdrop-blur-sm">
                <button
                  aria-controls={`faq-panel-${index}`}
                  aria-expanded={isOpen}
                  className="flex w-full items-center justify-between gap-4 text-left"
                  onClick={() => setOpenIndex(isOpen ? -1 : index)}
                  type="button"
                >
                  <span className="text-lg font-medium leading-7 text-white">
                    {item.question}
                  </span>
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-white/15 bg-white/10 text-xl text-amber-100">
                    {isOpen ? "-" : "+"}
                  </span>
                </button>

                <div
                  aria-hidden={!isOpen}
                  className={`grid overflow-hidden transition-[grid-template-rows,opacity] duration-300 ease-out ${
                    isOpen ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"
                  }`}
                  id={`faq-panel-${index}`}
                >
                  <div className="overflow-hidden">
                    <p className="pt-4 text-base leading-8 text-slate-300">
                      {item.answer}
                    </p>
                  </div>
                </div>
              </div>
            </Reveal>
          );
        })}
      </div>
    </section>
  );
}
