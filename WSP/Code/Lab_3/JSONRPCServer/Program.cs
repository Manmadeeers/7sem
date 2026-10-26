using JSONRPCServer.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddSingleton<CalculatorService>();
builder.Services.AddSingleton<JsonRpcDispatcher>();

var app = builder.Build();

app.MapControllers();

app.Run();