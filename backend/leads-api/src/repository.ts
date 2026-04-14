import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { runtimeConfig } from "./config";
import { LeadRecord, ValidatedLeadSubmission } from "./types";

const dynamoDbDocumentClient = DynamoDBDocumentClient.from(
  new DynamoDBClient({}),
);

export const buildLeadRecord = (
  lead: ValidatedLeadSubmission,
  requestId?: string,
): LeadRecord => {
  const createdAt = new Date().toISOString();
  const sk = `${createdAt}#${requestId ?? crypto.randomUUID()}`;

  return {
    pk: `LEAD#${lead.email}`,
    sk,
    email: lead.email,
    first_name: lead.firstName,
    last_name: lead.lastName,
    phone: lead.phone,
    message: lead.message,
    env_name: runtimeConfig.envName,
    business_name: runtimeConfig.businessName,
    source_site: lead.sourceSite ?? runtimeConfig.sourceSite,
    created_at: createdAt,
  };
};

export const saveLead = async (record: LeadRecord): Promise<void> => {
  await dynamoDbDocumentClient.send(
    new PutCommand({
      TableName: runtimeConfig.tableName,
      Item: record,
    }),
  );
};
