import Link from "next/link";

type SiteFooterProps = {
  siteName: string;
};

export function SiteFooter({ siteName }: SiteFooterProps) {
  return (
    <footer className="border-t border-slate-200 bg-white">
      <div className="mx-auto flex max-w-7xl flex-col gap-6 px-4 py-8 text-sm text-slate-600 sm:px-6 lg:px-8 md:flex-row md:items-center md:justify-between">
        <p className="max-w-2xl">
          {siteName} ships with server-rendered pages, metadata automation, structured data,
          and a same-origin backend proxy so teams can add product features without rebuilding
          the platform shell.
        </p>
        <div className="flex flex-wrap items-center gap-4">
          <Link href="/" className="transition hover:text-slate-950">
            Home
          </Link>
          <Link href="/connection" className="transition hover:text-slate-950">
            Connection check
          </Link>
          <Link href="/sitemap.xml" className="transition hover:text-slate-950">
            Sitemap
          </Link>
          <Link href="/robots.txt" className="transition hover:text-slate-950">
            Robots
          </Link>
        </div>
      </div>
    </footer>
  );
}
