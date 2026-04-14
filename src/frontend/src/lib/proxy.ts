const requestHeaderAllowList = [
  "accept",
  "authorization",
  "content-type",
  "if-match",
  "if-none-match",
  "range",
] as const;

const responseHeaderDenyList = new Set([
  "connection",
  "content-length",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

export function filterRequestHeaders(source: Headers): Headers {
  const target = new Headers();

  requestHeaderAllowList.forEach((headerName) => {
    const value = source.get(headerName);

    if (value) {
      target.set(headerName, value);
    }
  });

  return target;
}

export function filterResponseHeaders(source: Headers): Headers {
  const target = new Headers();

  source.forEach((value, key) => {
    if (!responseHeaderDenyList.has(key.toLowerCase())) {
      target.set(key, value);
    }
  });

  target.set("X-Robots-Tag", "noindex, nofollow");

  return target;
}
