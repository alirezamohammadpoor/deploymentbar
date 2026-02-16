import Image from "next/image";

export function Footer() {
  return (
    <footer className="border-t border-card-border">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 py-8 md:flex-row">
        <div className="flex items-center gap-2">
          <Image
            src="/app-icon.png"
            alt="DeployBar"
            width={20}
            height={20}
            className="rounded"
          />
          <span className="text-sm font-medium text-text-primary">
            DeployBar
          </span>
        </div>

        <div className="flex items-center gap-6">
          <a
            href="https://github.com/alirezamohammadpoor/deploymentbar"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors"
          >
            GitHub
          </a>
          <a
            href="https://twitter.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors"
          >
            Twitter
          </a>
          <a
            href="#"
            className="text-sm text-text-secondary hover:text-text-primary transition-colors"
          >
            Privacy
          </a>
        </div>

        <p className="text-sm text-text-secondary/60">
          &copy; 2026 DeployBar
        </p>
      </div>
    </footer>
  );
}
