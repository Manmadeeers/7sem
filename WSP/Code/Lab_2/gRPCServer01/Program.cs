using gRPCServer01.Services;
using Microsoft.AspNetCore.Server.Kestrel.Core;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenLocalhost(5000, endpoint =>
    {
        endpoint.Protocols = HttpProtocols.Http2;
    });
});

builder.Services.AddGrpc();

var app = builder.Build();

app.MapGrpcService<CalculatorService>();

app.Run();