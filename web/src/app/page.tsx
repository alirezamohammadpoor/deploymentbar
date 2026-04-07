import { Nav } from "@/components/Nav";
import { Hero } from "@/components/Hero";
import { BentoGrid } from "@/components/BentoGrid";
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
          <BentoGrid />
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
