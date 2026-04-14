import { LeadSubmissionInput, ValidatedLeadSubmission } from "./types";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const normalizeOptionalString = (value: unknown): string | undefined => {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed ? trimmed : undefined;
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
