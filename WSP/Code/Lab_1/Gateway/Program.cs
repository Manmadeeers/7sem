using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);

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

builder.Services
    .AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .AddTransforms(context =>
    {
        context.AddRequestHeaderRemove("Origin");
    });

var app = builder.Build();

app.UseRouting();

app.UseCors();

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "gateway"
}));

app.MapReverseProxy();

app.Run();