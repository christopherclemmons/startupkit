import {
  APIGatewayProxyEventV2,
  APIGatewayProxyStructuredResultV2,
} from "aws-lambda";
import { runtimeConfig } from "./config";
import { buildLeadRecord, saveLead } from "./repository";
import { jsonResponse } from "./response";
import { LeadSubmissionInput } from "./types";
import { validateLeadSubmission } from "./validation";

const parseBody = (body: string | undefined): LeadSubmissionInput => {
  if (!body) {
    throw new Error("Request body is required.");
  }

  try {
    return JSON.parse(body) as LeadSubmissionInput;
  } catch {
    throw new Error("Request body must be valid JSON.");
  }
};

export const handler = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyStructuredResultV2> => {
  const method = event.requestContext.http.method;

  if (method === "OPTIONS") {
    return jsonResponse(200, { message: "ok" });
  }

  if (method !== "POST") {
    return jsonResponse(405, { message: "Method not allowed." });
  }

  try {
    const input = parseBody(event.body);
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
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Internal server error.";
    const statusCode = message === "Internal server error." ? 500 : 400;

    console.error("Lead submission failed", {
      message,
      request_id: event.requestContext.requestId,
    });

    return jsonResponse(statusCode, { message });
  }
};
