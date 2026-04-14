import { useEffect } from "react";

export function SiteHead({
  siteName,
  pageTitle,
  metaDescription,
}: {
  siteName: string;
  pageTitle: string;
  metaDescription?: string;
}) {
  useEffect(() => {
    document.title = pageTitle || siteName;

    const existing = document.head.querySelector<HTMLMetaElement>(
      'meta[name="description"]',
    );
    const meta = existing ?? document.createElement("meta");

    meta.setAttribute("name", "description");
    meta.setAttribute("content", metaDescription ?? "");

    if (!existing) {
      document.head.appendChild(meta);
    }
  }, [metaDescription, pageTitle, siteName]);

  return null;
}
