using WS01_01.Services;

var builder = WebApplication.CreateBuilder(args);

var instanceName =
    builder.Configuration["INSTANCE_NAME"] ?? "ws01-local";

builder.Services.AddControllers();

builder.Services.AddSingleton<ApplicationResult>();

builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession(options =>
{
    options.Cookie.Name = $"WS01.Session.{instanceName}";
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    options.Cookie.Path = "/";

    options.IdleTimeout = TimeSpan.FromMinutes(30);
});

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

app.UseSession();

app.MapControllers();

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    instance = instanceName
}));

app.Run();