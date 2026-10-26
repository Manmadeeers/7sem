using Microsoft.AspNetCore.DataProtection;
using WS01_02.Services;

var builder = WebApplication.CreateBuilder(args);

var instanceName =
    builder.Configuration["INSTANCE_NAME"] ?? "ws02-local";

var keyPath =
    builder.Configuration["DataProtection:KeyPath"]
    ?? Path.Combine(builder.Environment.ContentRootPath, "keys");

Directory.CreateDirectory(keyPath);

builder.Services
    .AddDataProtection()
    .SetApplicationName("WS01-02")
    .PersistKeysToFileSystem(new DirectoryInfo(keyPath));

builder.Services.AddControllers();

builder.Services.AddSingleton<ApplicationResult>();
builder.Services.AddSingleton<StackCookieStore>();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:5500",
                "http://127.0.0.1:5500")
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials()
            .WithExposedHeaders("X-Instance");
    });
});

var app = builder.Build();

app.Use(async (context, next) =>
{
    context.Response.Headers["X-Instance"] = instanceName;
    context.Response.Headers["Cache-Control"] = "no-store";

    await next(context);
});

app.UseRouting();

app.UseCors();

app.MapControllers();

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    instance = instanceName
}));

app.Run();