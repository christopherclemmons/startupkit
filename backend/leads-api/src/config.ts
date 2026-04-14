import { SiteContentDto } from "./types";

type RuntimeConfig = {
  tableName: string;
  envName: string;
  businessName: string;
  sourceSite: string;
  adminEmail: string;
  defaultSiteContent: SiteContentDto;
};

const readEnv = (key: string): string => {
  const value = process.env[key];

  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${key}`);
  }

  return value.trim();
};

const parseDefaultSiteContent = (): SiteContentDto => {
  const raw = readEnv("DEFAULT_SITE_CONTENT_JSON");

  try {
    return JSON.parse(raw) as SiteContentDto;
  } catch (error) {
    throw new Error(
      `DEFAULT_SITE_CONTENT_JSON must be valid JSON: ${
        error instanceof Error ? error.message : "Unknown parsing error"
      }`,
    );
  }
};

export const runtimeConfig: RuntimeConfig = {
  tableName: readEnv("LEADS_TABLE_NAME"),
  envName: readEnv("ENV_NAME"),
  businessName: readEnv("BUSINESS_NAME"),
  sourceSite: readEnv("SOURCE_SITE"),
  adminEmail: readEnv("ADMIN_EMAIL").toLowerCase(),
  defaultSiteContent: parseDefaultSiteContent(),
};
