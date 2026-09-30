using Bstu.Results.Authentication;
using Bstu.Results.Collection;
using Microsoft.Data.Sqlite;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddProblemDetails();

var root = builder.Environment.ContentRootPath;

var resultsPath = Path.GetFullPath(
    builder.Configuration["Results:FilePath"]
        ?? "App_Data/results.json",
    root);

var identityPath = Path.GetFullPath(
    builder.Configuration["Identity:FilePath"]
        ?? "App_Data/identity.db",
    root);

Directory.CreateDirectory(
    Path.GetDirectoryName(identityPath)!);

builder.Services.AddResultsCollection(
    options => options.FilePath = resultsPath);

builder.Services.AddResultsAuthentication(
    builder.Configuration.GetSection("Jwt"),
    new SqliteConnectionStringBuilder
    {
        DataSource = identityPath
    }.ToString());

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();

if (!app.Environment.IsDevelopment())
    app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Учебные пользователи создаются только в Development.
// При повторном запуске существующие пароли не изменяются.
var accounts = app.Environment.IsDevelopment()
    ? builder.Configuration
        .GetSection("DemoUsers")
        .Get<SeedAccount[]>() ?? []
    : [];

await IdentitySeed.InitializeAsync(
    app.Services,
    accounts);

app.Run();