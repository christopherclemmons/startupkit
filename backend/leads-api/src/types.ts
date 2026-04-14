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

export type LeadRecord = {
  pk: string;
  sk: string;
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
