using Bstu.Results.Authentication;
using Bstu.Results.Collection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace REST01.Controllers;

[ApiController]
[Route("api/Results")]
[Produces("application/json")]
public sealed class ResultsController(
    Bstu.Results.Collection.Results results,
    Authenticate authenticate) : ControllerBase
{
    [HttpGet]
    [Authorize(Roles = ResultsRoles.Reader)]
    [ProducesResponseType(typeof(ResultItem[]), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var items = await results.GetAllAsync(ct);

        return items.Length == 0
            ? NoContent()
            : Ok(items);
    }

    [HttpGet("{k:int}")]
    [Authorize(Roles = ResultsRoles.Reader)]
    [ProducesResponseType(typeof(ResultItem), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int k, CancellationToken ct)
    {
        var item = await results.GetAsync(k, ct);

        return item is null
            ? Missing(k)
            : Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = ResultsRoles.Writer)]
    [ProducesResponseType(typeof(ResultItem), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Post(
        [FromBody] ValueRequest request,
        CancellationToken ct)
    {
        var item = await results.AddAsync(
            request.Value!,
            ct);

        return CreatedAtAction(
            nameof(Get),
            new { k = item.Key },
            item);
    }

    [HttpPut("{k:int}")]
    [Authorize(Roles = ResultsRoles.Writer)]
    [ProducesResponseType(typeof(ResultItem), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Put(
        int k,
        [FromBody] ValueRequest request,
        CancellationToken ct)
    {
        var item = await results.UpdateAsync(
            k,
            request.Value!,
            ct);

        return item is null
            ? Missing(k)
            : Ok(item);
    }

    [HttpDelete("{k:int}")]
    [Authorize(Roles = ResultsRoles.Writer)]
    [ProducesResponseType(typeof(ResultItem), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(
        int k,
        CancellationToken ct)
    {
        var item = await results.DeleteAsync(k, ct);

        return item is null
            ? Missing(k)
            : Ok(item);
    }

    [HttpPost("SignIn")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(JwtToken), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SignIn(
        [FromBody] SignInRequest request)
    {
        var result = await authenticate.SignInAsync(
            request.Login!,
            request.Password!);

        return result.Status switch
        {
            AuthenticationStatus.Success =>
                Ok(result.Token),

            AuthenticationStatus.UserNotFound =>
                Problem(
                    statusCode: 404,
                    detail: "User not found."),

            _ => Problem(
                statusCode: 400,
                detail: "Invalid password.")
        };
    }

    private ObjectResult Missing(int key) =>
        Problem(
            statusCode: StatusCodes.Status404NotFound,
            detail: $"Result with key {key} not found.");
}

public sealed class ValueRequest
{
    // Пустая строка допустима; null и отсутствие value — нет.
    [Required(AllowEmptyStrings = true)]
    public string? Value { get; init; }
}

public sealed class SignInRequest
{
    [Required]
    public string? Login { get; init; }

    [Required]
    public string? Password { get; init; }
}