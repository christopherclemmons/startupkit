import {
  LeadSubmissionInput,
  SiteContentDto,
  SiteContentInput,
  ValidatedLeadSubmission,
} from "./types";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const HEX_COLOR_REGEX = /^#(?:[0-9a-fA-F]{3}){1,2}$/;

const normalizeOptionalString = (value: unknown): string | undefined => {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed ? trimmed : undefined;
};

const requireString = (value: unknown, fieldName: string): string => {
  const normalized = normalizeOptionalString(value);

  if (!normalized) {
    throw new Error(`${fieldName} is required.`);
  }

  return normalized;
};

export const validateLeadSubmission = (
  input: LeadSubmissionInput,
): ValidatedLeadSubmission => {
  const honeypot = normalizeOptionalString(input.honeypot);

  if (honeypot) {
    throw new Error("Submission rejected.");
  }

  const email = normalizeOptionalString(input.email)?.toLowerCase();

  if (!email) {
    throw new Error("Email is required.");
  }

  if (!EMAIL_REGEX.test(email)) {
    throw new Error("Email format is invalid.");
  }

  return {
    email,
    firstName: normalizeOptionalString(input.first_name),
    lastName: normalizeOptionalString(input.last_name),
    phone: normalizeOptionalString(input.phone),
    message:
      normalizeOptionalString(input.business_interest) ??
      normalizeOptionalString(input.message),
    sourceSite: normalizeOptionalString(input.source_site),
  };
};

export const validateSiteContent = (
  input: SiteContentInput,
  defaults: Pick<SiteContentDto, "env_name" | "business_name" | "source_site">,
): SiteContentDto => {
  const features = Array.isArray(input.features) ? input.features : null;
  const faqs = Array.isArray(input.faqs) ? input.faqs : null;

  if (!features || features.length === 0) {
    throw new Error("features must contain at least one item.");
  }

  if (!faqs || faqs.length === 0) {
    throw new Error("faqs must contain at least one item.");
  }

  const siteContent: SiteContentDto = {
    site_name: requireString(input.site_name, "site_name"),
    business_name:
      normalizeOptionalString(input.business_name) ?? defaults.business_name,
    env_name: normalizeOptionalString(input.env_name) ?? defaults.env_name,
    source_site:
      normalizeOptionalString(input.source_site) ?? defaults.source_site,
    brand_color: requireString(input.brand_color, "brand_color"),
    page_title: requireString(input.page_title, "page_title"),
    meta_description: normalizeOptionalString(input.meta_description),
    hero_title: requireString(input.hero_title, "hero_title"),
    hero_subtitle: requireString(input.hero_subtitle, "hero_subtitle"),
    cta_text: requireString(input.cta_text, "cta_text"),
    hero_image_url: requireString(input.hero_image_url, "hero_image_url"),
    section_image_url: requireString(
      input.section_image_url,
      "section_image_url",
    ),
    features: features.map((item, index) => {
      if (!item || typeof item !== "object") {
        throw new Error(`features[${index}] must be an object.`);
      }

      const record = item as Record<string, unknown>;

      return {
        id: normalizeOptionalString(record.id) ?? `feature-${index + 1}`,
        title: requireString(record.title, `features[${index}].title`),
        description: requireString(
          record.description,
          `features[${index}].description`,
        ),
      };
    }),
    faqs: faqs.map((item, index) => {
      if (!item || typeof item !== "object") {
        throw new Error(`faqs[${index}] must be an object.`);
      }

      const record = item as Record<string, unknown>;

      return {
        id: normalizeOptionalString(record.id) ?? `faq-${index + 1}`,
        question: requireString(record.question, `faqs[${index}].question`),
        answer: requireString(record.answer, `faqs[${index}].answer`),
      };
    }),
  };

  if (!HEX_COLOR_REGEX.test(siteContent.brand_color)) {
    throw new Error("brand_color must be a valid hex color.");
  }

  return siteContent;
};
