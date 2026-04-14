const DEFAULT_SITE_NAME = "Terrastack";
const DEFAULT_SITE_URL = "http://localhost:3000";
const DEFAULT_DESCRIPTION =
  "Secure-by-default Next.js starter with strong technical SEO, accessible UX, and a backend-ready integration path for .NET APIs.";

const httpProtocols = new Set(["http:", "https:"]);

export function toDisplayName(value?: string | null): string {
  const candidate = value?.trim();

  if (!candidate) {
    return DEFAULT_SITE_NAME;
  }

  return candidate
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .split(" ")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function parseHttpUrl(value: string, fallback: string): URL {
  try {
    const parsed = new URL(value);

    if (httpProtocols.has(parsed.protocol)) {
      return parsed;
    }
  } catch {
    // Fall back to a safe local URL when env input is invalid.
  }

  return new URL(fallback);
}

export function getSiteName(): string {
  return toDisplayName(process.env.NEXT_PUBLIC_SITE_NAME);
}

export function getSiteUrl(): URL {
  return parseHttpUrl(process.env.NEXT_PUBLIC_SITE_URL ?? DEFAULT_SITE_URL, DEFAULT_SITE_URL);
}

export function getSiteDescription(): string {
  return DEFAULT_DESCRIPTION;
}

export function getBackendBaseUrl(): URL {
  return parseHttpUrl(process.env.BACKEND_INTERNAL_URL ?? "http://localhost:5000", "http://localhost:5000");
}

export const siteConfig = {
  name: getSiteName(),
  description: getSiteDescription(),
  url: getSiteUrl(),
  apiProxyBasePath: "/api/backend",
} as const;
