"use client";

import Image from "next/image";

export function Nav() {
  return (
    <header className="fixed top-4 left-1/2 -translate-x-1/2 z-[999] w-[calc(100%-32px)] max-w-[420px] lg:w-fit lg:max-w-none">
      <div className="flex items-center justify-between gap-8 rounded-xl border border-white/[0.08] bg-white/[0.06] py-2.5 pl-4 pr-2.5 backdrop-blur-[30px]">
        {/* Logo */}
        <a href="/" className="flex items-center gap-2">
          <Image
            src="/app-icon.png"
            alt="DeployBar"
            width={28}
            height={28}
            className="rounded-md"
          />
          <span className="text-lg font-medium text-text-primary">
            DeployBar
          </span>
        </a>

        {/* Nav links + CTA */}
        <div className="flex items-center gap-6">
          <a
            href="#features"
            className="hidden text-sm font-medium text-text-secondary transition-opacity hover:opacity-50 md:block"
          >
            Features
          </a>
          <a
            href="https://github.com"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden text-sm font-medium text-text-secondary transition-opacity hover:opacity-50 md:block"
          >
            GitHub
          </a>
          <a href="#waitlist">
            <button className="rounded-md border border-accent-blue/30 bg-accent-blue px-4 py-2 text-sm font-medium text-white transition-opacity hover:opacity-80">
              Download
            </button>
          </a>

          {/* Mobile hamburger */}
          <button className="flex h-8 w-8 flex-col items-center justify-center gap-1.5 md:hidden">
            <span className="block h-[1.5px] w-4 bg-text-secondary" />
            <span className="block h-[1.5px] w-4 bg-text-secondary" />
          </button>
        </div>
      </div>
    </header>
  );
}
