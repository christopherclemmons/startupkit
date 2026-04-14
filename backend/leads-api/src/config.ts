type RuntimeConfig = {
  tableName: string;
  envName: string;
  businessName: string;
  sourceSite: string;
};

const readEnv = (key: string): string => {
  const value = process.env[key];

  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${key}`);
  }

  return value.trim();
};

export const runtimeConfig: RuntimeConfig = {
  tableName: readEnv("LEADS_TABLE_NAME"),
  envName: readEnv("ENV_NAME"),
  businessName: readEnv("BUSINESS_NAME"),
  sourceSite: readEnv("SOURCE_SITE"),
};
