using Bstu.Results.Authentication;
using Bstu.Results.Collection;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddProblemDetails();

var resultsPath = Path.GetFullPath(
    builder.Configuration["Results:FilePath"]
        ?? "App_Data/results.json",
    builder.Environment.ContentRootPath);

builder.Services.AddResultsCollection(
    options => options.FilePath = resultsPath);

builder.Services.AddResultsAuthentication(builder.Environment);

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();

if (!app.Environment.IsDevelopment())
    app.UseHttpsRedirection();

app.UseResultsAuthentication();

app.MapControllers();
app.Run();