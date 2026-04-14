export type LeadSubmissionInput = {
  email?: unknown;
  first_name?: unknown;
  last_name?: unknown;
  phone?: unknown;
  business_interest?: unknown;
  message?: unknown;
  source_site?: unknown;
  honeypot?: unknown;
};

export type ValidatedLeadSubmission = {
  email: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  message?: string;
  sourceSite?: string;
};

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

export type SiteContentDto = {
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

export type SiteContentInput = {
  site_name?: unknown;
  business_name?: unknown;
  env_name?: unknown;
  source_site?: unknown;
  brand_color?: unknown;
  page_title?: unknown;
  meta_description?: unknown;
  hero_title?: unknown;
  hero_subtitle?: unknown;
  cta_text?: unknown;
  hero_image_url?: unknown;
  section_image_url?: unknown;
  features?: unknown;
  faqs?: unknown;
};

export type SiteContentRecord = {
  pk: string;
  sk: string;
  entity_type: "SITE_CONTENT";
  site_name: string;
  business_name: string;
  env_name: string;
  source_site: string;
  content: SiteContentDto;
  content_version: number;
  created_at: string;
  updated_at: string;
  updated_by: string;
};

export type LeadRecord = {
  pk: string;
  sk: string;
  entity_type: "LEAD";
  site_pk: string;
  email: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  message?: string;
  env_name: string;
  business_name: string;
  source_site: string;
  created_at: string;
};
