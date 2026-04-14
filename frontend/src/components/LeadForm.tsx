import { FormEvent, useState } from "react";
import { SiteContent } from "../config/siteConfig";
import { Reveal } from "./Reveal";

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

export function LeadForm({
  content,
  apiBaseUrl,
}: {
  content: SiteContent;
  apiBaseUrl: string;
}) {
  const [formState, setFormState] = useState<FormState>(initialFormState);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<SubmitStatus>({
    state: "idle",
    message: null,
  });

  const endpoint = `${apiBaseUrl.replace(/\/$/, "")}/leads`;

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
          source_site: content.source_site,
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
    <Reveal>
      <form
        className="space-y-4 rounded-[1.75rem] border border-white/10 bg-white p-6 text-slate-900 shadow-[0_24px_70px_rgba(15,23,42,0.18)] md:p-7"
        id="lead-form"
        onSubmit={handleSubmit}
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.28em] text-brand">
              Lead capture
            </p>
            <h3 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">
              Send {content.site_name} a qualified inquiry.
            </h3>
          </div>
          <span className="rounded-full bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-700">
            {content.env_name}
          </span>
        </div>

        {submitStatus.message ? (
          <p
            className={`rounded-2xl px-4 py-3 text-sm font-medium ${
              submitStatus.state === "success"
                ? "bg-emerald-50 text-emerald-800"
                : "bg-rose-50 text-rose-800"
            }`}
          >
            {submitStatus.message}
          </p>
        ) : null}

        <div className="grid gap-4 md:grid-cols-2">
          <div>
            <label className="mb-2 block text-sm font-medium" htmlFor="firstName">
              First name
            </label>
            <input
              className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand focus:ring-2 focus:ring-brand/15"
              id="firstName"
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
              className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand focus:ring-2 focus:ring-brand/15"
              id="lastName"
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
              className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand focus:ring-2 focus:ring-brand/15"
              id="email"
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
              className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand focus:ring-2 focus:ring-brand/15"
              id="phone"
              name="phone"
              onChange={(event) => updateField("phone", event.target.value)}
              placeholder="+1 555 123 4567"
              type="tel"
              value={formState.phone}
            />
          </div>
        </div>

        <div>
          <label
            className="mb-2 block text-sm font-medium"
            htmlFor="businessInterest"
          >
            Business interest or message
          </label>
          <textarea
            className="min-h-28 w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-brand focus:ring-2 focus:ring-brand/15"
            id="businessInterest"
            name="businessInterest"
            onChange={(event) =>
              updateField("businessInterest", event.target.value)
            }
            placeholder="Tell us what you want to validate or learn."
            value={formState.businessInterest}
          />
        </div>

        <div aria-hidden="true" className="hidden">
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
          className="inline-flex w-full items-center justify-center rounded-full bg-brand px-6 py-3 font-semibold text-white transition hover:-translate-y-0.5 hover:opacity-95 disabled:cursor-not-allowed disabled:opacity-70"
          disabled={isSubmitting}
          type="submit"
        >
          {isSubmitting ? "Submitting..." : content.cta_text}
        </button>

        <p className="text-xs leading-6 text-slate-500">
          Submissions are tagged with this site context and sent through the API
          only.
        </p>
      </form>
    </Reveal>
  );
}
