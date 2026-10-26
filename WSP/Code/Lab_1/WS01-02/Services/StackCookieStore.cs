using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;

namespace WS01_02.Services;

public sealed class StackCookieStore
{
    public const string CookieName = "WS02.Stack";
    public const int MaxDepth = 100;

    private readonly IDataProtector _protector;

    public StackCookieStore(IDataProtectionProvider provider)
    {
        _protector = provider.CreateProtector("WS01-02.Stack.v1");
    }

    public Stack<int>? Read(HttpContext context)
    {
        if (!context.Request.Cookies.TryGetValue(
                CookieName,
                out var protectedValue))
        {
            return new Stack<int>();
        }

        try
        {
            var json = _protector.Unprotect(protectedValue);

            var values = JsonSerializer.Deserialize<int[]>(json);

            if (values is null || values.Length > MaxDepth)
            {
                throw new JsonException("Invalid stack data.");
            }

            return new Stack<int>(values);
        }
        catch (Exception exception) when (
            exception is CryptographicException
                or JsonException
                or FormatException)
        {
            context.Response.Cookies.Delete(
                CookieName,
                new CookieOptions
                {
                    Path = "/"
                });

            return null;
        }
    }

    public void Write(HttpContext context, Stack<int> stack)
    {
        var bottomToTop = stack.Reverse().ToArray();

        var json = JsonSerializer.Serialize(bottomToTop);

        var protectedValue = _protector.Protect(json);

        context.Response.Cookies.Append(
            CookieName,
            protectedValue,
            new CookieOptions
            {
                HttpOnly = true,
                Secure = context.Request.IsHttps,
                SameSite = SameSiteMode.Lax,
                IsEssential = true,
                Path = "/"
            });
    }
}