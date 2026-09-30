using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
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
    IOptions<JwtOptions> options)
{
    public async Task<AuthenticationResult> SignInAsync(
        string login,
        string password)
    {
        var user = await users.FindByNameAsync(login);

        if (user is null)
            return new(AuthenticationStatus.UserNotFound);

        // Проверка пароля средствами Identity.
        if (!await users.CheckPasswordAsync(user, password))
            return new(AuthenticationStatus.InvalidCredentials);

        var jwt = options.Value;
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
}

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddResultsAuthentication(
        this IServiceCollection services,
        IConfigurationSection jwtSection,
        string connectionString)
    {
        services.AddOptions<JwtOptions>()
            .Bind(jwtSection)
            .ValidateDataAnnotations()
            .Validate(
                x => Encoding.UTF8.GetByteCount(x.SigningKey) >= 32,
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

        return services;
    }
}

public sealed record SeedAccount(
    string Login,
    string Password,
    string[] Roles);

public static class IdentitySeed
{
    public static async Task InitializeAsync(
        IServiceProvider provider,
        IEnumerable<SeedAccount> accounts)
    {
        await using var scope = provider.CreateAsyncScope();

        var db = scope.ServiceProvider
            .GetRequiredService<IdentityDatabase>();

        await db.Database.EnsureCreatedAsync();

        var roles = scope.ServiceProvider
            .GetRequiredService<RoleManager<IdentityRole>>();

        var users = scope.ServiceProvider
            .GetRequiredService<UserManager<IdentityUser>>();

        foreach (var role in new[]
                 {
                     ResultsRoles.Reader,
                     ResultsRoles.Writer
                 })
        {
            if (!await roles.RoleExistsAsync(role))
                Check(await roles.CreateAsync(new IdentityRole(role)));
        }

        foreach (var account in accounts)
        {
            if (account.Roles.Any(role =>
                    role != ResultsRoles.Reader &&
                    role != ResultsRoles.Writer))
            {
                throw new InvalidOperationException("Unknown seed role.");
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