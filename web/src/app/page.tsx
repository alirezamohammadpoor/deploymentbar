import { Nav } from "@/components/Nav";
import { Hero } from "@/components/Hero";
import { BentoGrid } from "@/components/BentoGrid";
import { FAQ } from "@/components/FAQ";
import { FinalCTA } from "@/components/FinalCTA";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <BentoGrid />
        <FAQ />
        <FinalCTA />
      </main>
      <Footer />
    </>
  );
}
