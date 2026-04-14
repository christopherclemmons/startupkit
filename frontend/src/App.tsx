import { CSSProperties } from "react";
import { CtaSection } from "./components/CtaSection";
import { FeaturesSection } from "./components/FeaturesSection";
import { HeroSection } from "./components/HeroSection";
import { ImageSection } from "./components/ImageSection";
import { LeadForm } from "./components/LeadForm";
import { siteConfig } from "./config/siteConfig";

function App() {
  return (
    <main
      className="mx-auto flex min-h-screen max-w-6xl flex-col px-6 py-8 text-slate-900"
      style={
        {
          "--brand-color": siteConfig.brandColor,
        } as CSSProperties
      }
    >
      <HeroSection config={siteConfig} />
      <ImageSection config={siteConfig} />
      <FeaturesSection features={siteConfig.features} />
      <section className="grid gap-8 rounded-[2rem] bg-slate-950 px-8 py-12 text-white md:grid-cols-[0.9fr_1.1fr] md:px-12">
        <CtaSection config={siteConfig} />
        <LeadForm config={siteConfig} />
      </section>
    </main>
  );
}

export default App;
