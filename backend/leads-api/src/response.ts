import { APIGatewayProxyStructuredResultV2 } from "aws-lambda";

const responseHeaders = {
  "content-type": "application/json",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "OPTIONS,GET,POST,PUT",
  "access-control-allow-headers": "authorization,content-type",
};

export const jsonResponse = (
  statusCode: number,
  body: Record<string, unknown>,
): APIGatewayProxyStructuredResultV2 => ({
  statusCode,
  headers: responseHeaders,
  body: JSON.stringify(body),
});
