import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import "./globals.css";

export const metadata: Metadata = {
  title: "DeployBar — All your deployments. One glance away.",
  description:
    "DeployBar lives in your macOS menu bar. See every Vercel deployment the moment it starts. Monitor progress. Catch failures instantly.",
  openGraph: {
    title: "DeployBar — All your deployments. One glance away.",
    description:
      "A native macOS menu bar app for monitoring Vercel deployments in real-time.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${GeistSans.variable} ${GeistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
