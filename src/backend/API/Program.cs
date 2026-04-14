using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using API.Data;
using API.Services;
using System.Threading.RateLimiting;
using System.Reflection;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

var isDevelopment = builder.Environment.IsDevelopment();

var requireAuthentication = builder.Configuration.GetValue("Security:RequireAuthentication",
    builder.Configuration.GetValue("AUTH_REQUIRED", false));

var enableHttpsRedirection = builder.Configuration.GetValue("Security:EnableHttpsRedirection",
    builder.Configuration.GetValue("ENABLE_HTTPS_REDIRECT", false));

var enableSwagger = builder.Configuration.GetValue("Swagger:Enabled",
    builder.Configuration.GetValue("ENABLE_SWAGGER", isDevelopment));

var autoMigrateDatabase = builder.Configuration.GetValue("Database:AutoMigrate",
    builder.Configuration.GetValue("DB_AUTO_MIGRATE", isDevelopment));
    
// Security hardening: global API throttling defaults to reduce abuse and burst traffic impact.
var rateLimitPermitLimit = builder.Configuration.GetValue("Security:RateLimiting:PermitLimit", 120);
var rateLimitWindowSeconds = builder.Configuration.GetValue("Security:RateLimiting:WindowSeconds", 60);

// Configure CORS
var configuredCorsOrigins = builder.Configuration["CORS_ALLOWED_ORIGINS"];
var allowedCorsOrigins = string.IsNullOrWhiteSpace(configuredCorsOrigins) && isDevelopment
    ? new[] { "http://localhost:3000", "https://localhost:3000" }
    : (configuredCorsOrigins ?? string.Empty)
        .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

if (!isDevelopment && allowedCorsOrigins.Length == 0)
{
    // Security hardening: fail fast in non-dev when CORS is not explicitly configured.
    throw new InvalidOperationException("CORS_ALLOWED_ORIGINS must be configured outside development.");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontendApp", policy =>
    {
        policy.WithOrigins(allowedCorsOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Configure Entity Framework
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();

// Register services
builder.Services.AddScoped<ProfileService>();

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    // Security hardening: trust X-Forwarded-* headers from reverse proxies (ALB/CloudFront path).
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.ForwardLimit = 2;
});

builder.Services.AddRateLimiter(options =>
{
    // Security hardening: return HTTP 429 when clients exceed configured limits.
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var remoteIp = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(remoteIp, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = rateLimitPermitLimit,
            Window = TimeSpan.FromSeconds(rateLimitWindowSeconds),
            QueueLimit = 0,
            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
            AutoReplenishment = true
        });
    });
});

if (requireAuthentication)
{
    // Security hardening: JWT auth is optional in dev, mandatory in production when enabled.
    var authAuthority = builder.Configuration["Security:Jwt:Authority"] ?? builder.Configuration["AUTH_AUTHORITY"];
    var authAudience = builder.Configuration["Security:Jwt:Audience"] ?? builder.Configuration["AUTH_AUDIENCE"];

    if (string.IsNullOrWhiteSpace(authAuthority) || string.IsNullOrWhiteSpace(authAudience))
    {
        throw new InvalidOperationException("Security:Jwt:Authority and Security:Jwt:Audience are required when Security:RequireAuthentication=true.");
    }

    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.Authority = authAuthority;
            options.Audience = authAudience;
            // Security hardening: require HTTPS metadata endpoints outside development.
            options.RequireHttpsMetadata = !isDevelopment;
        });

    builder.Services.AddAuthorization();
}

// Configure Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "APP_NAME API", Version = "v1" });

    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        // Pull XML documentation into Swagger when available.
        c.IncludeXmlComments(xmlPath);
    }

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "JWT Authorization header using the Bearer scheme."
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!isDevelopment)
{
    // Security hardening: HSTS instructs browsers to use HTTPS for subsequent requests.
    app.UseHsts();
}

if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "APP_NAME API v1");
    });
}

if (enableHttpsRedirection)
{
    // Security hardening: enforce HTTPS at the API edge when infra TLS is configured.
    app.UseHttpsRedirection();
}

app.UseForwardedHeaders();
app.UseRateLimiter();

app.Use(async (context, next) =>
{
    // Security hardening: baseline response headers to reduce common browser-side attack vectors.
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    context.Response.Headers["Referrer-Policy"] = "no-referrer";
    context.Response.Headers["X-Permitted-Cross-Domain-Policies"] = "none";
    await next();
});

app.UseCors("AllowFrontendApp");

if (requireAuthentication)
{
    // Security hardening: activate authentication/authorization middleware only when configured.
    app.UseAuthentication();
    app.UseAuthorization();
}

var controllerEndpoints = app.MapControllers();
if (requireAuthentication)
{
    // Security hardening: require authenticated access to API routes by default.
    controllerEndpoints.RequireAuthorization();
}

if (autoMigrateDatabase)
{
    // Keep schema in sync with EF migrations when enabled.
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    context.Database.Migrate();
}

app.Run();

public partial class Program
{
}

