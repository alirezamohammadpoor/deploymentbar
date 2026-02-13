"use client";

import Image from "next/image";

export function Nav() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 border-b border-card-border bg-background/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-[90vw] md:max-w-[30vw] items-center justify-between px-6 py-4">
        <div className="flex items-center gap-2">
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
        </div>

        <div className="flex items-center gap-8">
          <a
            href="#features"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors"
          >
            Features
          </a>
          <a
            href="https://github.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors"
          >
            GitHub
          </a>
        </div>
      </div>
    </nav>
  );
}
