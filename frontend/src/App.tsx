import { CSSProperties } from "react";
import { FaqSection } from "./components/FaqSection";
import { CtaSection } from "./components/CtaSection";
import { FeaturesSection } from "./components/FeaturesSection";
import { HeroSection } from "./components/HeroSection";
import { ImageSection } from "./components/ImageSection";
import { LeadForm } from "./components/LeadForm";
import { siteConfig } from "./config/siteConfig";

function App() {
  return (
    <main
      className="relative isolate min-h-screen overflow-hidden px-4 py-5 text-slate-900 sm:px-6 lg:px-8 lg:py-8"
      style={
        {
          "--brand-color": siteConfig.brandColor,
        } as CSSProperties
      }
    >
      <div className="pointer-events-none absolute inset-0 -z-10 overflow-hidden">
        <div className="absolute left-1/2 top-0 h-80 w-80 -translate-x-1/2 rounded-full bg-brand/20 blur-3xl" />
        <div className="absolute right-[-4rem] top-40 h-72 w-72 rounded-full bg-cyan-200/40 blur-3xl" />
        <div className="absolute bottom-0 left-[-5rem] h-80 w-80 rounded-full bg-amber-100/60 blur-3xl" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(255,255,255,0.85),transparent_42%),linear-gradient(180deg,#f8fafc_0%,#eefaf7_100%)]" />
      </div>

      <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 lg:gap-8">
        <HeroSection config={siteConfig} />
        <ImageSection config={siteConfig} />
        <FeaturesSection features={siteConfig.features} />
        <FaqSection items={siteConfig.faqs} />
        <section className="grid gap-8 rounded-[2rem] border border-slate-200/80 bg-slate-950 px-6 py-8 text-white shadow-2xl shadow-slate-950/20 md:grid-cols-[0.9fr_1.1fr] md:px-10 md:py-10">
          <CtaSection config={siteConfig} />
          <LeadForm config={siteConfig} />
        </section>
      </div>
    </main>
  );
}

export default App;
