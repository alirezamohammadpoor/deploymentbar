import Image from "next/image";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/links";

const COLUMNS: { heading: string; links: { label: string; href: string }[] }[] =
  [
    {
      heading: "Product",
      links: [
        { label: "Features", href: "#features" },
        { label: "Download", href: DOWNLOAD_URL },
      ],
    },
    {
      heading: "Resources",
      links: [
        { label: "GitHub", href: GITHUB_URL },
        { label: "Releases", href: `${GITHUB_URL}/releases` },
      ],
    },
    {
      heading: "Legal",
      links: [{ label: "Privacy", href: "#" }],
    },
  ];

export function Footer() {
  return (
    <footer className="bg-background">
      <div className="mx-auto max-w-[1200px] px-6">
        <div className="h-px w-full bg-hairline" />
        <div className="grid grid-cols-2 gap-10 py-[88px] md:grid-cols-12 md:gap-6">
          {/* brand */}
          <div className="col-span-2 md:col-span-3">
            <div className="flex items-center gap-2">
              <Image
                src="/app-icon.png"
                alt=""
                width={22}
                height={22}
                className="rounded-[6px]"
              />
              <span className="text-[15px] font-medium text-text-primary">
                Deploymentbar
              </span>
            </div>
            <p className="mt-3 text-[13px] text-text-dim">
              All your deployments. One glance away.
            </p>
          </div>

          {/* link columns */}
          {COLUMNS.map((col) => (
            <div key={col.heading} className="md:col-span-3">
              <h4 className="text-[12px] font-medium text-text-secondary">
                {col.heading}
              </h4>
              <ul className="mt-3 space-y-2">
                {col.links.map((l) => (
                  <li key={l.label}>
                    <a
                      href={l.href}
                      className="text-[13px] text-text-dim transition-colors hover:text-text-secondary"
                    >
                      {l.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="border-t border-hairline py-6">
          <p className="font-mono text-[11px] text-text-dim">
            © 2026 Deploymentbar · Free public beta · macOS 14+
          </p>
        </div>
      </div>
    </footer>
  );
}
