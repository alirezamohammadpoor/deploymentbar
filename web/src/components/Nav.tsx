import Image from "next/image";
import Link from "next/link";
import { Pill } from "./ui/primitives";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/links";

export function Nav() {
  return (
    <header className="fixed inset-x-0 top-0 z-[999]">
      <nav className="relative mx-auto flex max-w-[1200px] items-center justify-between px-6 py-5">
        {/* brand — left */}
        <Link href="/" className="flex items-center gap-2">
          <Image
            src="/app-icon.png"
            alt=""
            width={24}
            height={24}
            className="rounded-[6px]"
          />
          <span className="text-[15px] font-medium tracking-tight text-text-primary">
            Deploymentbar
          </span>
        </Link>

        {/* links — centered, out of flow so they never collide with the ends */}
        <div className="absolute left-1/2 hidden -translate-x-1/2 items-center gap-8 md:flex">
          <a
            href="#features"
            className="text-[13px] text-text-secondary transition-colors hover:text-text-primary"
          >
            Features
          </a>
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-[13px] text-text-secondary transition-colors hover:text-text-primary"
          >
            GitHub
          </a>
        </div>

        {/* actions — right, partitioned by a faint vertical hairline */}
        <div className="flex items-center gap-4">
          <span
            aria-hidden
            className="hidden h-5 w-px bg-hairline md:block"
          />
          <Pill href={DOWNLOAD_URL} className="text-[13px]">
            Download
          </Pill>
        </div>
      </nav>
    </header>
  );
}
