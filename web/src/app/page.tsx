import { Nav } from "@/components/Nav";
import { Hero } from "@/components/Hero";
import { FeatureShowcase } from "@/components/FeatureShowcase";
import { Platform } from "@/components/Platform";
import { GetStarted } from "@/components/GetStarted";
import { Statement } from "@/components/Statement";
import { FAQ } from "@/components/FAQ";
import { FinalCTA } from "@/components/FinalCTA";
import { Footer } from "@/components/Footer";
import { ScrollReveal } from "@/components/ScrollReveal";

export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <ScrollReveal>
          <FeatureShowcase />
        </ScrollReveal>
        <ScrollReveal>
          <Platform />
        </ScrollReveal>
        <ScrollReveal>
          <GetStarted />
        </ScrollReveal>
        <ScrollReveal>
          <Statement />
        </ScrollReveal>
        <ScrollReveal>
          <FAQ />
        </ScrollReveal>
        <ScrollReveal>
          <FinalCTA />
        </ScrollReveal>
      </main>
      <Footer />
    </>
  );
}
