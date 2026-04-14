type RequiredEnvKey =
  | "VITE_SITE_NAME"
  | "VITE_HERO_TITLE"
  | "VITE_HERO_SUBTITLE"
  | "VITE_CTA_TEXT"
  | "VITE_API_BASE_URL"
  | "VITE_ENV_NAME"
  | "VITE_HERO_IMAGE_URL"
  | "VITE_SECTION_IMAGE_URL"
  | "VITE_BRAND_COLOR"
  | "VITE_FEATURE_1_TITLE"
  | "VITE_FEATURE_1_DESCRIPTION"
  | "VITE_FEATURE_2_TITLE"
  | "VITE_FEATURE_2_DESCRIPTION"
  | "VITE_FEATURE_3_TITLE"
  | "VITE_FEATURE_3_DESCRIPTION"
  | "VITE_FAQ_1_QUESTION"
  | "VITE_FAQ_1_ANSWER"
  | "VITE_FAQ_2_QUESTION"
  | "VITE_FAQ_2_ANSWER"
  | "VITE_FAQ_3_QUESTION"
  | "VITE_FAQ_3_ANSWER";

type FeatureItem = {
  title: string;
  description: string;
};

type FaqItem = {
  question: string;
  answer: string;
};

type SiteConfig = {
  siteName: string;
  heroTitle: string;
  heroSubtitle: string;
  ctaText: string;
  apiBaseUrl: string;
  envName: string;
  heroImageUrl: string;
  sectionImageUrl: string;
  brandColor: string;
  features: FeatureItem[];
  faqs: FaqItem[];
};

const readEnv = (key: RequiredEnvKey): string => {
  const value = import.meta.env[key];

  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${key}`);
  }

  return value.trim();
};

export const siteConfig: SiteConfig = {
  siteName: readEnv("VITE_SITE_NAME"),
  heroTitle: readEnv("VITE_HERO_TITLE"),
  heroSubtitle: readEnv("VITE_HERO_SUBTITLE"),
  ctaText: readEnv("VITE_CTA_TEXT"),
  apiBaseUrl: readEnv("VITE_API_BASE_URL"),
  envName: readEnv("VITE_ENV_NAME"),
  heroImageUrl: readEnv("VITE_HERO_IMAGE_URL"),
  sectionImageUrl: readEnv("VITE_SECTION_IMAGE_URL"),
  brandColor: readEnv("VITE_BRAND_COLOR"),
  features: [
    {
      title: readEnv("VITE_FEATURE_1_TITLE"),
      description: readEnv("VITE_FEATURE_1_DESCRIPTION"),
    },
    {
      title: readEnv("VITE_FEATURE_2_TITLE"),
      description: readEnv("VITE_FEATURE_2_DESCRIPTION"),
    },
    {
      title: readEnv("VITE_FEATURE_3_TITLE"),
      description: readEnv("VITE_FEATURE_3_DESCRIPTION"),
    },
  ],
  faqs: [
    {
      question: readEnv("VITE_FAQ_1_QUESTION"),
      answer: readEnv("VITE_FAQ_1_ANSWER"),
    },
    {
      question: readEnv("VITE_FAQ_2_QUESTION"),
      answer: readEnv("VITE_FAQ_2_ANSWER"),
    },
    {
      question: readEnv("VITE_FAQ_3_QUESTION"),
      answer: readEnv("VITE_FAQ_3_ANSWER"),
    },
  ],
};

export type { FeatureItem, FaqItem, SiteConfig };
