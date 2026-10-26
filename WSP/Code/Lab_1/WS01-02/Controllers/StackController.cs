using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using WS01_02.Services;

namespace WS01_02.Controllers;

[ApiController]
[Route("stack")]
public sealed class StackController : ControllerBase
{
    private readonly ApplicationResult _applicationResult;
    private readonly StackCookieStore _cookieStore;

    public StackController(
        ApplicationResult applicationResult,
        StackCookieStore cookieStore)
    {
        _applicationResult = applicationResult;
        _cookieStore = cookieStore;
    }

    [HttpGet]
    public ActionResult<StackResponse> Get()
    {
        var stack = _cookieStore.Read(HttpContext);

        if (stack is null)
        {
            return InvalidCookie();
        }

        return Reply(stack);
    }

    [HttpPost]
    public ActionResult<StackResponse> Post(
        [FromBody] SetResultRequest request)
    {
        var stack = _cookieStore.Read(HttpContext);

        if (stack is null)
        {
            return InvalidCookie();
        }

        _applicationResult.Value = request.Result!.Value;

        return Reply(stack);
    }

    [HttpPut]
    public ActionResult<StackResponse> Put(
        [FromQuery(Name = "ADD"), Required] int? add)
    {
        var stack = _cookieStore.Read(HttpContext);

        if (stack is null)
        {
            return InvalidCookie();
        }

        if (stack.Count >= StackCookieStore.MaxDepth)
        {
            return BadRequest(new
            {
                error =
                    $"The stack cannot contain more than " +
                    $"{StackCookieStore.MaxDepth} values."
            });
        }

        stack.Push(add!.Value);

        return Reply(stack);
    }

    [HttpDelete]
    public ActionResult<StackResponse> Delete()
    {
        var stack = _cookieStore.Read(HttpContext);

        if (stack is null)
        {
            return InvalidCookie();
        }

        if (stack.Count == 0)
        {
            return Conflict(new
            {
                error = "The stack is empty."
            });
        }

        stack.Pop();

        return Reply(stack);
    }

    private ActionResult<StackResponse> Reply(Stack<int> stack)
    {
        _cookieStore.Write(HttpContext, stack);

        var result = _applicationResult.Value;
        var top = stack.Count == 0 ? 0 : stack.Peek();

        return Ok(new StackResponse((long)result + top));
    }

    private BadRequestObjectResult InvalidCookie()
    {
        return BadRequest(new
        {
            error =
                "The stack cookie is invalid and has been cleared. " +
                "Send the request again to start with an empty stack."
        });
    }
}

public sealed class SetResultRequest
{
    [Required]
    [JsonPropertyName("RESULT")]
    public int? Result { get; init; }
}

public sealed record StackResponse(
    [property: JsonPropertyName("RESULT")] long Result);