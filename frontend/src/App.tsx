import { CSSProperties, FormEvent, useEffect, useMemo, useState } from "react";
import { CtaSection } from "./components/CtaSection";
import { FaqSection } from "./components/FaqSection";
import { FeaturesSection } from "./components/FeaturesSection";
import { HeroSection } from "./components/HeroSection";
import { ImageSection } from "./components/ImageSection";
import { LeadForm } from "./components/LeadForm";
import { SiteHead } from "./components/SiteHead";
import { appConfig, SiteContent } from "./config/siteConfig";

type ApiResponse<T> = {
  data: T;
  message?: string;
};

type AuthState =
  | { status: "disabled" }
  | { status: "signed_out" }
  | { status: "signing_in" }
  | { status: "signed_in"; idToken: string; email?: string }
  | { status: "error"; message: string };

const isAdminRoute =
  window.location.pathname.replace(/\/$/, "") ===
  appConfig.adminRoutePath.replace(/\/$/, "");

const buildApiUrl = (path: string) =>
  `${appConfig.apiBaseUrl.replace(/\/$/, "")}${path}`;

const readStoredTokens = (): { idToken: string; email?: string } | null => {
  const idToken = window.sessionStorage.getItem("admin_id_token");

  if (!idToken) {
    return null;
  }

  const email = window.sessionStorage.getItem("admin_email") ?? undefined;
  return { idToken, email };
};

const parseJwtPayload = (token: string): Record<string, unknown> => {
  const [, payload] = token.split(".");

  if (!payload) {
    return {};
  }

  return JSON.parse(window.atob(payload.replace(/-/g, "+").replace(/_/g, "/")));
};

const createPkceVerifier = () => {
  const random = crypto.getRandomValues(new Uint8Array(32));
  return Array.from(random, (byte) => byte.toString(16).padStart(2, "0")).join("");
};

const toBase64Url = (buffer: ArrayBuffer) =>
  window
    .btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");

const createPkceChallenge = async (verifier: string) => {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(verifier),
  );

  return toBase64Url(digest);
};

const exchangeCodeForTokens = async (
  code: string,
): Promise<{ id_token: string }> => {
  const cognito = appConfig.cognito;
  const verifier = window.sessionStorage.getItem("admin_code_verifier");

  if (!cognito || !verifier) {
    throw new Error("Missing Cognito configuration for admin login.");
  }

  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: cognito.clientId,
    code,
    redirect_uri: cognito.redirectUri,
    code_verifier: verifier,
  });

  const response = await fetch(`https://${cognito.domain}/oauth2/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (!response.ok) {
    throw new Error("Unable to complete admin login.");
  }

  return (await response.json()) as { id_token: string };
};

const beginAdminLogin = async () => {
  const cognito = appConfig.cognito;

  if (!cognito) {
    throw new Error("Cognito is not configured for this landing page.");
  }

  const verifier = createPkceVerifier();
  const challenge = await createPkceChallenge(verifier);

  window.sessionStorage.setItem("admin_code_verifier", verifier);

  const params = new URLSearchParams({
    response_type: "code",
    client_id: cognito.clientId,
    redirect_uri: cognito.redirectUri,
    scope: "openid email profile",
    code_challenge_method: "S256",
    code_challenge: challenge,
  });

  window.location.assign(`https://${cognito.domain}/login?${params.toString()}`);
};

const signOutAdmin = () => {
  const cognito = appConfig.cognito;

  window.sessionStorage.removeItem("admin_id_token");
  window.sessionStorage.removeItem("admin_email");
  window.sessionStorage.removeItem("admin_code_verifier");

  if (!cognito) {
    return;
  }

  const params = new URLSearchParams({
    client_id: cognito.clientId,
    logout_uri: cognito.logoutUri,
  });

  window.location.assign(`https://${cognito.domain}/logout?${params.toString()}`);
};

function AdminScreen({
  content,
  onContentUpdated,
}: {
  content: SiteContent;
  onContentUpdated: (content: SiteContent) => void;
}) {
  const [authState, setAuthState] = useState<AuthState>(() => {
    if (!appConfig.cognito) {
      return { status: "disabled" };
    }

    const stored = readStoredTokens();
    return stored ? { status: "signed_in", ...stored } : { status: "signed_out" };
  });
  const [draft, setDraft] = useState(() => JSON.stringify(content, null, 2));
  const [saveState, setSaveState] = useState<{
    status: "idle" | "saving" | "saved" | "error";
    message?: string;
  }>({ status: "idle" });

  useEffect(() => {
    setDraft(JSON.stringify(content, null, 2));
  }, [content]);

  useEffect(() => {
    const code = new URLSearchParams(window.location.search).get("code");

    if (!code || !appConfig.cognito) {
      return;
    }

    setAuthState({ status: "signing_in" });

    exchangeCodeForTokens(code)
      .then(({ id_token }) => {
        const claims = parseJwtPayload(id_token);
        const email = typeof claims.email === "string" ? claims.email : undefined;

        window.sessionStorage.setItem("admin_id_token", id_token);

        if (email) {
          window.sessionStorage.setItem("admin_email", email);
        }

        window.history.replaceState({}, "", appConfig.adminRoutePath);
        setAuthState({ status: "signed_in", idToken: id_token, email });
      })
      .catch((error) => {
        setAuthState({
          status: "error",
          message:
            error instanceof Error ? error.message : "Unable to complete login.",
        });
      });
  }, []);

  const handleSave = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (authState.status !== "signed_in") {
      return;
    }

    setSaveState({ status: "saving" });

    try {
      const parsed = JSON.parse(draft) as SiteContent;
      const response = await fetch(buildApiUrl("/admin/site-content"), {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${authState.idToken}`,
        },
        body: JSON.stringify(parsed),
      });

      const payload = (await response.json()) as ApiResponse<SiteContent>;

      if (!response.ok) {
        throw new Error(payload.message ?? "Unable to save site content.");
      }

      onContentUpdated(payload.data);
      setSaveState({
        status: "saved",
        message: "Content saved for this landing page.",
      });
    } catch (error) {
      setSaveState({
        status: "error",
        message:
          error instanceof Error ? error.message : "Unable to save site content.",
      });
    }
  };

  return (
    <main className="min-h-screen bg-slate-950 px-4 py-6 text-white sm:px-6">
      <div className="mx-auto max-w-5xl space-y-6">
        <div className="rounded-[2rem] border border-white/10 bg-white/5 p-6 backdrop-blur">
          <p className="text-sm uppercase tracking-[0.3em] text-emerald-300">
            Hidden Admin Route
          </p>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight">
            {content.site_name} content editor
          </h1>
          <p className="mt-3 max-w-3xl text-slate-300">
            This route is not linked anywhere publicly. The JSON document below is
            the per-site DTO stored in DynamoDB for this landing page only.
          </p>
        </div>

        {authState.status === "disabled" ? (
          <div className="rounded-[2rem] border border-amber-400/20 bg-amber-300/10 p-6 text-amber-100">
            Cognito is not configured in the frontend environment yet.
          </div>
        ) : null}

        {authState.status === "signed_out" || authState.status === "error" ? (
          <div className="rounded-[2rem] border border-white/10 bg-white/5 p-6">
            <p className="text-slate-300">
              {authState.status === "error"
                ? authState.message
                : "Sign in with the Cognito-managed email flow to edit this site."}
            </p>
            <button
              className="mt-4 inline-flex rounded-full bg-emerald-400 px-5 py-3 font-semibold text-slate-950"
              onClick={() => void beginAdminLogin()}
              type="button"
            >
              Sign in
            </button>
          </div>
        ) : null}

        {authState.status === "signing_in" ? (
          <div className="rounded-[2rem] border border-white/10 bg-white/5 p-6 text-slate-300">
            Completing admin login...
          </div>
        ) : null}

        {authState.status === "signed_in" ? (
          <form
            className="space-y-4 rounded-[2rem] border border-white/10 bg-white/5 p-6"
            onSubmit={handleSave}
          >
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-sm uppercase tracking-[0.3em] text-slate-400">
                  Signed in
                </p>
                <p className="mt-1 text-lg font-medium">
                  {authState.email ?? "Admin session active"}
                </p>
              </div>
              <button
                className="rounded-full border border-white/15 px-4 py-2 text-sm font-semibold"
                onClick={signOutAdmin}
                type="button"
              >
                Sign out
              </button>
            </div>

            {saveState.message ? (
              <p
                className={`rounded-2xl px-4 py-3 text-sm ${
                  saveState.status === "saved"
                    ? "bg-emerald-400/15 text-emerald-100"
                    : "bg-rose-400/15 text-rose-100"
                }`}
              >
                {saveState.message}
              </p>
            ) : null}

            <textarea
              className="min-h-[32rem] w-full rounded-[1.5rem] border border-white/10 bg-slate-950/80 p-5 font-mono text-sm text-slate-100 outline-none focus:border-emerald-300"
              onChange={(event) => setDraft(event.target.value)}
              spellCheck={false}
              value={draft}
            />

            <div className="flex flex-wrap items-center justify-between gap-3">
              <p className="text-sm text-slate-400">
                Save updates only applies to the current site’s content record.
              </p>
              <button
                className="rounded-full bg-emerald-400 px-5 py-3 font-semibold text-slate-950 disabled:opacity-60"
                disabled={saveState.status === "saving"}
                type="submit"
              >
                {saveState.status === "saving" ? "Saving..." : "Save content"}
              </button>
            </div>
          </form>
        ) : null}
      </div>
    </main>
  );
}

function LandingPage({ content }: { content: SiteContent }) {
  return (
    <>
      <SiteHead
        metaDescription={content.meta_description}
        pageTitle={content.page_title}
        siteName={content.site_name}
      />
      <main
        className="relative isolate min-h-screen overflow-hidden px-4 py-5 text-slate-900 sm:px-6 lg:px-8 lg:py-8"
        style={
          {
            "--brand-color": content.brand_color,
          } as CSSProperties
        }
      >
        <div className="pointer-events-none absolute inset-0 -z-10 overflow-hidden">
          <div className="absolute left-1/2 top-0 h-80 w-80 -translate-x-1/2 rounded-full bg-brand/20 blur-3xl" />
          <div className="absolute right-[-4rem] top-40 h-72 w-72 rounded-full bg-cyan-200/40 blur-3xl" />
          <div className="absolute bottom-0 left-[-5rem] h-80 w-80 rounded-full bg-amber-100/60 blur-3xl" />
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(255,255,255,0.85),transparent_42%),linear-gradient(180deg,#f8fafc_0%,#eefaf7_100%)]" />
        </div>

        <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 lg:gap-8">
          <HeroSection content={content} />
          <ImageSection content={content} />
          <FeaturesSection features={content.features} />
          <FaqSection items={content.faqs} />
          <section className="grid gap-8 rounded-[2rem] border border-slate-200/80 bg-slate-950 px-6 py-8 text-white shadow-2xl shadow-slate-950/20 md:grid-cols-[0.9fr_1.1fr] md:px-10 md:py-10">
            <CtaSection content={content} />
            <LeadForm apiBaseUrl={appConfig.apiBaseUrl} content={content} />
          </section>
        </div>
      </main>
    </>
  );
}

function App() {
  const [content, setContent] = useState<SiteContent>(appConfig.defaultContent);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    if (isAdminRoute) {
      return;
    }

    fetch(buildApiUrl("/site-content"))
      .then(async (response) => {
        const payload = (await response.json()) as ApiResponse<SiteContent>;

        if (!response.ok) {
          throw new Error(payload.message ?? "Unable to load site content.");
        }

        setContent(payload.data);
      })
      .catch((error) => {
        setLoadError(
          error instanceof Error
            ? error.message
            : "Unable to load site content from the API.",
        );
      });
  }, []);

  const page = useMemo(() => {
    if (isAdminRoute) {
      return <AdminScreen content={content} onContentUpdated={setContent} />;
    }

    return <LandingPage content={content} />;
  }, [content]);

  return (
    <>
      {page}
      {loadError && !isAdminRoute ? (
        <div className="fixed bottom-4 right-4 max-w-sm rounded-2xl bg-amber-50 px-4 py-3 text-sm text-amber-900 shadow-xl">
          {loadError} Using fallback content from local config.
        </div>
      ) : null}
    </>
  );
}

export default App;
