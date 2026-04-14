import {
  APIGatewayProxyEventV2,
  APIGatewayProxyStructuredResultV2,
} from "aws-lambda";
import { runtimeConfig } from "./config";
import {
  buildLeadRecord,
  getPublishedSiteContent,
  upsertSiteContent,
  saveLead,
} from "./repository";
import { jsonResponse } from "./response";
import { LeadSubmissionInput, SiteContentInput } from "./types";
import { validateLeadSubmission, validateSiteContent } from "./validation";

const parseBody = <T>(body: string | undefined): T => {
  if (!body) {
    throw new Error("Request body is required.");
  }

  try {
    return JSON.parse(body) as T;
  } catch {
    throw new Error("Request body must be valid JSON.");
  }
};

const getAdminEmailFromEvent = (
  event: APIGatewayProxyEventV2,
): string | undefined => {
  const claims = (
    event.requestContext as APIGatewayProxyEventV2["requestContext"] & {
      authorizer?: {
        jwt?: {
          claims?: Record<string, string>;
        };
      };
    }
  ).authorizer?.jwt?.claims;
  const emailClaim = claims?.email ?? claims?.["cognito:username"];
  return typeof emailClaim === "string" ? emailClaim.toLowerCase() : undefined;
};

const assertAdminAccess = (event: APIGatewayProxyEventV2): string => {
  const adminEmail = getAdminEmailFromEvent(event);

  if (!adminEmail) {
    throw new Error("Unauthorized.");
  }

  if (adminEmail !== runtimeConfig.adminEmail) {
    throw new Error("Forbidden.");
  }

  return adminEmail;
};

const handleLeadSubmission = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyStructuredResultV2> => {
  const input = parseBody<LeadSubmissionInput>(event.body);
  const lead = validateLeadSubmission(input);
  const record = buildLeadRecord(lead, event.requestContext.requestId);

  await saveLead(record);

  console.log("Lead submission stored", {
    env_name: runtimeConfig.envName,
    business_name: runtimeConfig.businessName,
    source_site: record.source_site,
    email: record.email,
    request_id: event.requestContext.requestId,
  });

  return jsonResponse(201, {
    message: "Lead submission received.",
    data: {
      email: record.email,
      created_at: record.created_at,
    },
  });
};

const handleGetSiteContent = async (): Promise<APIGatewayProxyStructuredResultV2> => {
  const content = await getPublishedSiteContent();

  return jsonResponse(200, {
    data: content,
  });
};

const handleUpdateSiteContent = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyStructuredResultV2> => {
  const updatedBy = assertAdminAccess(event);
  const input = parseBody<SiteContentInput>(event.body);
  const content = validateSiteContent(input, {
    env_name: runtimeConfig.envName,
    business_name: runtimeConfig.businessName,
    source_site: runtimeConfig.sourceSite,
  });
  const record = await upsertSiteContent(content, updatedBy);

  console.log("Site content updated", {
    env_name: runtimeConfig.envName,
    updated_by: updatedBy,
    content_version: record.content_version,
    request_id: event.requestContext.requestId,
  });

  return jsonResponse(200, {
    message: "Site content updated.",
    data: record.content,
    meta: {
      content_version: record.content_version,
      updated_at: record.updated_at,
      updated_by: record.updated_by,
    },
  });
};

export const handler = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyStructuredResultV2> => {
  const method = event.requestContext.http.method;
  const route = event.rawPath.replace(/\/$/, "") || "/";

  if (method === "OPTIONS") {
    return jsonResponse(200, { message: "ok" });
  }

  try {
    if (method === "GET" && route === "/site-content") {
      return await handleGetSiteContent();
    }

    if (method === "POST" && route === "/leads") {
      return await handleLeadSubmission(event);
    }

    if (method === "PUT" && route === "/admin/site-content") {
      return await handleUpdateSiteContent(event);
    }

    return jsonResponse(405, { message: "Method not allowed." });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Internal server error.";
    const statusCode =
      message === "Unauthorized."
        ? 401
        : message === "Forbidden."
          ? 403
          : message === "Internal server error."
            ? 500
            : 400;

    console.error("API request failed", {
      message,
      route,
      request_id: event.requestContext.requestId,
    });

    return jsonResponse(statusCode, { message });
  }
};
