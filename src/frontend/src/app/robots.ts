import type { MetadataRoute } from "next";
import { siteConfig } from "@/lib/site";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: ["/", "/connection"],
        disallow: ["/api/"],
      },
    ],
    sitemap: `${siteConfig.url.toString()}/sitemap.xml`,
    host: siteConfig.url.toString(),
  };
}
