import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";
import { runtimeConfig } from "./config";
import { LeadRecord, SiteContentDto, SiteContentRecord, ValidatedLeadSubmission } from "./types";

const dynamoDbDocumentClient = DynamoDBDocumentClient.from(
  new DynamoDBClient({}),
);

const sitePk = `SITE#${runtimeConfig.envName}`;
const siteSk = "CONTENT#CURRENT";

export const buildLeadRecord = (
  lead: ValidatedLeadSubmission,
  requestId?: string,
): LeadRecord => {
  const createdAt = new Date().toISOString();
  const sk = `${createdAt}#${requestId ?? crypto.randomUUID()}`;

  return {
    pk: `LEAD#${lead.email}`,
    sk,
    entity_type: "LEAD",
    site_pk: sitePk,
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

export const getSiteContent = async (): Promise<SiteContentRecord | null> => {
  const result = await dynamoDbDocumentClient.send(
    new GetCommand({
      TableName: runtimeConfig.tableName,
      Key: {
        pk: sitePk,
        sk: siteSk,
      },
    }),
  );

  return (result.Item as SiteContentRecord | undefined) ?? null;
};

export const getPublishedSiteContent = async (): Promise<SiteContentDto> => {
  const record = await getSiteContent();
  return record?.content ?? runtimeConfig.defaultSiteContent;
};

export const upsertSiteContent = async (
  content: SiteContentDto,
  updatedBy: string,
): Promise<SiteContentRecord> => {
  const existing = await getSiteContent();
  const now = new Date().toISOString();
  const nextVersion = (existing?.content_version ?? 0) + 1;

  await dynamoDbDocumentClient.send(
    new UpdateCommand({
      TableName: runtimeConfig.tableName,
      Key: {
        pk: sitePk,
        sk: siteSk,
      },
      UpdateExpression: [
        "SET entity_type = :entityType",
        "content = :content",
        "site_name = :siteName",
        "business_name = :businessName",
        "env_name = :envName",
        "source_site = :sourceSite",
        "updated_at = :updatedAt",
        "updated_by = :updatedBy",
        "content_version = :contentVersion",
        "created_at = if_not_exists(created_at, :createdAt)",
      ].join(", "),
      ExpressionAttributeValues: {
        ":entityType": "SITE_CONTENT",
        ":content": content,
        ":siteName": content.site_name,
        ":businessName": content.business_name,
        ":envName": content.env_name,
        ":sourceSite": content.source_site,
        ":updatedAt": now,
        ":updatedBy": updatedBy,
        ":contentVersion": nextVersion,
        ":createdAt": existing?.created_at ?? now,
      },
      ReturnValues: "ALL_NEW",
    }),
  );

  return {
    pk: sitePk,
    sk: siteSk,
    entity_type: "SITE_CONTENT",
    site_name: content.site_name,
    business_name: content.business_name,
    env_name: content.env_name,
    source_site: content.source_site,
    content,
    content_version: nextVersion,
    created_at: existing?.created_at ?? now,
    updated_at: now,
    updated_by: updatedBy,
  };
};
