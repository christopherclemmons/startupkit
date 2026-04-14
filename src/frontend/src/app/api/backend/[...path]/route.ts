import { NextRequest, NextResponse } from "next/server";
import { getBackendBaseUrl } from "@/lib/site";
import { filterRequestHeaders, filterResponseHeaders } from "@/lib/proxy";

export const dynamic = "force-dynamic";

const supportedMethods = new Set(["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"]);

function buildTargetUrl(request: NextRequest, path: string[]): URL {
  const backendBaseUrl = getBackendBaseUrl();
  const safePath = path.map((segment) => encodeURIComponent(segment)).join("/");
  const targetUrl = new URL(`${backendBaseUrl.toString().replace(/\/$/, "")}/${safePath}`);
  targetUrl.search = new URL(request.url).search;

  return targetUrl;
}

async function proxyRequest(
  request: NextRequest,
  context: { params: { path: string[] } },
): Promise<NextResponse> {
  if (!supportedMethods.has(request.method)) {
    return NextResponse.json({ error: "Method not allowed" }, { status: 405 });
  }

  const targetUrl = buildTargetUrl(request, context.params.path ?? []);

  try {
    const requestHeaders = filterRequestHeaders(request.headers);
    const proxiedResponse = await fetch(targetUrl, {
      method: request.method,
      headers: requestHeaders,
      body: request.method === "GET" || request.method === "HEAD"
        ? undefined
        : await request.arrayBuffer(),
      cache: "no-store",
      redirect: "manual",
    });

    const responseHeaders = filterResponseHeaders(proxiedResponse.headers);
    const responseBody =
      request.method === "HEAD" ? null : Buffer.from(await proxiedResponse.arrayBuffer());

    return new NextResponse(responseBody, {
      status: proxiedResponse.status,
      headers: responseHeaders,
    });
  } catch {
    return NextResponse.json(
      {
        error: "Backend service is unavailable.",
      },
      {
        status: 502,
        headers: {
          "Cache-Control": "no-store",
          "X-Robots-Tag": "noindex, nofollow",
        },
      },
    );
  }
}

export async function GET(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}

export async function POST(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}

export async function PUT(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}

export async function PATCH(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}

export async function DELETE(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}

export async function OPTIONS(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}

export async function HEAD(request: NextRequest, context: { params: { path: string[] } }) {
  return proxyRequest(request, context);
}
