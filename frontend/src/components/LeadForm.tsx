import { FormEvent, useMemo, useState } from "react";
import { SiteConfig } from "../config/siteConfig";

type LeadFormProps = {
  config: SiteConfig;
};

type FormState = {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  businessInterest: string;
  companyWebsite: string;
};

type SubmitStatus =
  | { state: "idle"; message: string | null }
  | { state: "success"; message: string }
  | { state: "error"; message: string };

const initialFormState: FormState = {
  firstName: "",
  lastName: "",
  email: "",
  phone: "",
  businessInterest: "",
  companyWebsite: "",
};

export function LeadForm({ config }: LeadFormProps) {
  const [formState, setFormState] = useState<FormState>(initialFormState);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<SubmitStatus>({
    state: "idle",
    message: null,
  });

  const endpoint = useMemo(
    () => `${config.apiBaseUrl.replace(/\/$/, "")}/leads`,
    [config.apiBaseUrl],
  );

  const updateField = (field: keyof FormState, value: string) => {
    setFormState((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsSubmitting(true);
    setSubmitStatus({ state: "idle", message: null });

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          first_name: formState.firstName || undefined,
          last_name: formState.lastName || undefined,
          email: formState.email,
          phone: formState.phone || undefined,
          business_interest: formState.businessInterest || undefined,
          source_site: config.siteName,
          honeypot: formState.companyWebsite || undefined,
        }),
      });

      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to submit your request.");
      }

      setSubmitStatus({
        state: "success",
        message:
          payload.message ||
          "Thanks. Your interest has been captured successfully.",
      });
      setFormState(initialFormState);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Unexpected submission error.";

      setSubmitStatus({ state: "error", message });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form
      id="lead-form"
      className="space-y-4 rounded-[1.5rem] bg-white p-6 text-slate-900"
      onSubmit={handleSubmit}
    >
      <div className="grid gap-4 md:grid-cols-2">
        <div>
          <label className="mb-2 block text-sm font-medium" htmlFor="firstName">
            First name
          </label>
          <input
            id="firstName"
            className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand"
            name="firstName"
            onChange={(event) => updateField("firstName", event.target.value)}
            placeholder="Jordan"
            type="text"
            value={formState.firstName}
          />
        </div>

        <div>
          <label className="mb-2 block text-sm font-medium" htmlFor="lastName">
            Last name
          </label>
          <input
            id="lastName"
            className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand"
            name="lastName"
            onChange={(event) => updateField("lastName", event.target.value)}
            placeholder="Lee"
            type="text"
            value={formState.lastName}
          />
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <div>
          <label className="mb-2 block text-sm font-medium" htmlFor="email">
            Email
          </label>
          <input
            required
            id="email"
            className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand"
            name="email"
            onChange={(event) => updateField("email", event.target.value)}
            placeholder="jordan@example.com"
            type="email"
            value={formState.email}
          />
        </div>

        <div>
          <label className="mb-2 block text-sm font-medium" htmlFor="phone">
            Phone
          </label>
          <input
            id="phone"
            className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand"
            name="phone"
            onChange={(event) => updateField("phone", event.target.value)}
            placeholder="+1 555 123 4567"
            type="tel"
            value={formState.phone}
          />
        </div>
      </div>

      <div>
        <label className="mb-2 block text-sm font-medium" htmlFor="businessInterest">
          Business interest or message
        </label>
        <textarea
          id="businessInterest"
          className="min-h-28 w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand"
          name="businessInterest"
          onChange={(event) =>
            updateField("businessInterest", event.target.value)
          }
          placeholder="Tell us what you want to validate or learn."
          value={formState.businessInterest}
        />
      </div>

      <div className="hidden" aria-hidden="true">
        <label htmlFor="companyWebsite">Company website</label>
        <input
          id="companyWebsite"
          name="companyWebsite"
          onChange={(event) => updateField("companyWebsite", event.target.value)}
          tabIndex={-1}
          type="text"
          value={formState.companyWebsite}
        />
      </div>

      <button
        className="inline-flex w-full items-center justify-center rounded-full bg-brand px-6 py-3 font-semibold text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-70"
        disabled={isSubmitting}
        type="submit"
      >
        {isSubmitting ? "Submitting..." : config.ctaText}
      </button>

      {submitStatus.message ? (
        <p
          className={
            submitStatus.state === "success"
              ? "text-sm font-medium text-emerald-700"
              : "text-sm font-medium text-rose-700"
          }
        >
          {submitStatus.message}
        </p>
      ) : null}
    </form>
  );
}
