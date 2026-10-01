using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Bstu.Results.Authentication;

public sealed class IdentityDatabase(
    DbContextOptions<IdentityDatabase> options)
    : IdentityDbContext<IdentityUser, IdentityRole, string>(options)
{
}

public sealed class JwtOptions
{
    [Required]
    public string Issuer { get; set; } = "REST01";

    [Required]
    public string Audience { get; set; } = "REST01.Client";

    [Required, MinLength(32)]
    public string SigningKey { get; set; } = "";

    [Range(1, 1440)]
    public int LifetimeMinutes { get; set; } = 60;
}

public sealed class AuthenticationSettings
{
    public string IdentityFilePath { get; set; } =
        "App_Data/identity.db";

    public SeedAccount[] DemoUsers { get; set; } = [];
}

public sealed class SeedAccount
{
    public string Login { get; set; } = "";
    public string Password { get; set; } = "";
    public string[] Roles { get; set; } = [];
}

public static class ResultsRoles
{
    public const string Reader = "READER";
    public const string Writer = "WRITER";
}

public enum AuthenticationStatus
{
    Success,
    UserNotFound,
    InvalidCredentials
}

public sealed record JwtToken(
    string Token,
    DateTime ExpiresAtUtc);

public sealed record AuthenticationResult(
    AuthenticationStatus Status,
    JwtToken? Token = null);

public sealed class Authenticate(
    UserManager<IdentityUser> users,
    RoleManager<IdentityRole> roles,
    IdentityDatabase database,
    IOptions<JwtOptions> jwtOptions,
    IOptions<AuthenticationSettings> settings,
    IHostEnvironment environment)
{
    public async Task<AuthenticationResult> SignInAsync(
        string login,
        string password)
    {
        var user = await users.FindByNameAsync(login);

        if (user is null)
            return new(AuthenticationStatus.UserNotFound);

        if (!await users.CheckPasswordAsync(user, password))
            return new(AuthenticationStatus.InvalidCredentials);

        var jwt = jwtOptions.Value;
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(jwt.LifetimeMinutes);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),
            new(JwtRegisteredClaimNames.UniqueName, user.UserName!),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))
        };

        foreach (var role in await users.GetRolesAsync(user))
            claims.Add(new Claim("role", role));

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwt.SigningKey)),
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: jwt.Issuer,
            audience: jwt.Audience,
            claims: claims,
            notBefore: now,
            expires: expires,
            signingCredentials: credentials);

        return new AuthenticationResult(
            AuthenticationStatus.Success,
            new JwtToken(
                new JwtSecurityTokenHandler().WriteToken(token),
                expires));
    }

    public async Task InitializeAsync(
        CancellationToken ct = default)
    {
        // Validate JWT settings before changing the database.
        _ = jwtOptions.Value;

        await database.Database.EnsureCreatedAsync(ct);

        foreach (var role in new[]
                 {
                     ResultsRoles.Reader,
                     ResultsRoles.Writer
                 })
        {
            if (!await roles.RoleExistsAsync(role))
                Check(await roles.CreateAsync(new IdentityRole(role)));
        }

        if (!environment.IsDevelopment())
            return;

        foreach (var account in settings.Value.DemoUsers)
        {
            ct.ThrowIfCancellationRequested();

            if (string.IsNullOrWhiteSpace(account.Login) ||
                string.IsNullOrWhiteSpace(account.Password) ||
                account.Roles.Any(role =>
                    role != ResultsRoles.Reader &&
                    role != ResultsRoles.Writer))
            {
                throw new InvalidOperationException(
                    "Invalid demo account configuration.");
            }

            var user = await users.FindByNameAsync(account.Login);

            if (user is null)
            {
                user = new IdentityUser(account.Login);

                Check(await users.CreateAsync(
                    user,
                    account.Password));
            }

            foreach (var role in account.Roles)
            {
                if (!await users.IsInRoleAsync(user, role))
                    Check(await users.AddToRoleAsync(user, role));
            }
        }
    }

    private static void Check(IdentityResult result)
    {
        if (!result.Succeeded)
        {
            throw new InvalidOperationException(
                string.Join(
                    "; ",
                    result.Errors.Select(error => error.Description)));
        }
    }
}

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddResultsAuthentication(
        this IServiceCollection services,
        IHostEnvironment environment)
    {
        var configuration = LoadSettings(environment);

        var identityPath = Path.GetFullPath(
            configuration["IdentityFilePath"]
                ?? "App_Data/identity.db",
            environment.ContentRootPath);

        Directory.CreateDirectory(
            Path.GetDirectoryName(identityPath)!);

        var connectionString = new SqliteConnectionStringBuilder
        {
            DataSource = identityPath
        }.ToString();

        services.Configure<AuthenticationSettings>(configuration);

        services.AddOptions<JwtOptions>()
            .Bind(configuration.GetSection("Jwt"))
            .ValidateDataAnnotations()
            .Validate(
                options =>
                    Encoding.UTF8.GetByteCount(options.SigningKey) >= 32,
                "JWT signing key must have at least 32 UTF-8 bytes.")
            .ValidateOnStart();

        services.AddDbContext<IdentityDatabase>(
            options => options.UseSqlite(connectionString));

        services.AddIdentityCore<IdentityUser>(options =>
        {
            options.Password.RequiredLength = 8;
            options.Password.RequireDigit = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireNonAlphanumeric = true;
        })
        .AddRoles<IdentityRole>()
        .AddEntityFrameworkStores<IdentityDatabase>();

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer();

        services
            .AddOptions<JwtBearerOptions>(
                JwtBearerDefaults.AuthenticationScheme)
            .Configure<IOptions<JwtOptions>>((bearer, configured) =>
            {
                var jwt = configured.Value;

                bearer.MapInboundClaims = false;

                bearer.TokenValidationParameters =
                    new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,

                        RequireSignedTokens = true,
                        RequireExpirationTime = true,

                        ValidIssuer = jwt.Issuer,
                        ValidAudience = jwt.Audience,

                        IssuerSigningKey = new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(jwt.SigningKey)),

                        ValidAlgorithms = [SecurityAlgorithms.HmacSha256],

                        NameClaimType = "unique_name",
                        RoleClaimType = "role",

                        ClockSkew = TimeSpan.Zero
                    };
            });

        services.AddAuthorization();
        services.AddScoped<Authenticate>();
        services.AddHostedService<AuthenticationInitializer>();

        return services;
    }

    public static IApplicationBuilder UseResultsAuthentication(
        this IApplicationBuilder app) =>
        app.UseAuthentication().UseAuthorization();

    private static IConfigurationRoot LoadSettings(
        IHostEnvironment environment)
    {
        var assembly = typeof(Authenticate).Assembly;

        using var main = assembly.GetManifestResourceStream(
            "BSTU.Results.Authenticate.authenticationsettings.json")
            ?? throw new InvalidOperationException(
                "Embedded authentication settings not found.");

        using var development = environment.IsDevelopment()
            ? assembly.GetManifestResourceStream(
                "BSTU.Results.Authenticate.authenticationsettings.Development.json")
                ?? throw new InvalidOperationException(
                    "Embedded development authentication settings not found.")
            : null;

        var builder = new ConfigurationBuilder()
            .AddJsonStream(main);

        if (development is not null)
            builder.AddJsonStream(development);

        // Example: BSTU_AUTH_Jwt__SigningKey overrides Jwt:SigningKey.
        builder.AddEnvironmentVariables(prefix: "BSTU_AUTH_");

        return builder.Build();
    }
}

internal sealed class AuthenticationInitializer(
    IServiceScopeFactory scopes) : IHostedService
{
    public async Task StartAsync(CancellationToken ct)
    {
        await using var scope = scopes.CreateAsyncScope();

        await scope.ServiceProvider
            .GetRequiredService<Authenticate>()
            .InitializeAsync(ct);
    }

    public Task StopAsync(CancellationToken ct) =>
        Task.CompletedTask;
}