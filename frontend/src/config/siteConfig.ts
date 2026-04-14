export type SiteFeature = {
  id: string;
  title: string;
  description: string;
};

export type SiteFaq = {
  id: string;
  question: string;
  answer: string;
};

export type SiteContent = {
  site_name: string;
  business_name: string;
  env_name: string;
  source_site: string;
  brand_color: string;
  page_title: string;
  meta_description?: string;
  hero_title: string;
  hero_subtitle: string;
  cta_text: string;
  hero_image_url: string;
  section_image_url: string;
  features: SiteFeature[];
  faqs: SiteFaq[];
};

type RequiredEnvKey =
  | "VITE_API_BASE_URL"
  | "VITE_ENV_NAME"
  | "VITE_SITE_NAME"
  | "VITE_SITE_CONTENT_JSON";

type OptionalEnvKey =
  | "VITE_ADMIN_ROUTE_PATH"
  | "VITE_COGNITO_DOMAIN"
  | "VITE_COGNITO_CLIENT_ID"
  | "VITE_COGNITO_REDIRECT_URI"
  | "VITE_COGNITO_LOGOUT_URI";

export type AppRuntimeConfig = {
  apiBaseUrl: string;
  envName: string;
  siteName: string;
  adminRoutePath: string;
  defaultContent: SiteContent;
  cognito?: {
    domain: string;
    clientId: string;
    redirectUri: string;
    logoutUri: string;
  };
};

const readEnv = (key: RequiredEnvKey): string => {
  const value = import.meta.env[key];

  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${key}`);
  }

  return value.trim();
};

const readOptionalEnv = (key: OptionalEnvKey): string | undefined => {
  const value = import.meta.env[key];
  return value && value.trim() ? value.trim() : undefined;
};

const parseSiteContent = (raw: string): SiteContent => {
  try {
    return JSON.parse(raw) as SiteContent;
  } catch (error) {
    throw new Error(
      `Invalid JSON in VITE_SITE_CONTENT_JSON: ${
        error instanceof Error ? error.message : "Unknown parsing error"
      }`,
    );
  }
};

const cognitoDomain = readOptionalEnv("VITE_COGNITO_DOMAIN");
const cognitoClientId = readOptionalEnv("VITE_COGNITO_CLIENT_ID");
const cognitoRedirectUri = readOptionalEnv("VITE_COGNITO_REDIRECT_URI");
const cognitoLogoutUri = readOptionalEnv("VITE_COGNITO_LOGOUT_URI");

export const appConfig: AppRuntimeConfig = {
  apiBaseUrl: readEnv("VITE_API_BASE_URL"),
  envName: readEnv("VITE_ENV_NAME"),
  siteName: readEnv("VITE_SITE_NAME"),
  adminRoutePath: readOptionalEnv("VITE_ADMIN_ROUTE_PATH") ?? "/admin",
  defaultContent: parseSiteContent(readEnv("VITE_SITE_CONTENT_JSON")),
  cognito:
    cognitoDomain && cognitoClientId && cognitoRedirectUri && cognitoLogoutUri
      ? {
          domain: cognitoDomain,
          clientId: cognitoClientId,
          redirectUri: cognitoRedirectUri,
          logoutUri: cognitoLogoutUri,
        }
      : undefined,
};
