using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using WS01_01.Services;

namespace WS01_01.Controllers;

[ApiController]
[Route("stack")]
public sealed class StackController : ControllerBase
{
    private const string StackKey = "StackValues";

    private readonly ApplicationResult _applicationResult;

    public StackController(ApplicationResult applicationResult)
    {
        _applicationResult = applicationResult;
    }

    [HttpGet]
    public async Task<ActionResult<StackResponse>> Get(
        CancellationToken cancellationToken)
    {
        var stack = await LoadStackAsync(cancellationToken);

        return Ok(CreateResponse(stack));
    }

    [HttpPost]
    public async Task<ActionResult<StackResponse>> Post(
        [FromBody] SetResultRequest request,
        CancellationToken cancellationToken)
    {
        var stack = await LoadStackAsync(cancellationToken);

        _applicationResult.Value = request.Result!.Value;

        return Ok(CreateResponse(stack));
    }

    [HttpPut]
    public async Task<ActionResult<StackResponse>> Put(
        [FromQuery(Name = "ADD"), Required] int? add,
        CancellationToken cancellationToken)
    {
        var stack = await LoadStackAsync(cancellationToken);

        stack.Push(add!.Value);

        SaveStack(stack);

        return Ok(CreateResponse(stack));
    }

    [HttpDelete]
    public async Task<ActionResult<StackResponse>> Delete(
        CancellationToken cancellationToken)
    {
        var stack = await LoadStackAsync(cancellationToken);

        if (stack.Count == 0)
        {
            return Conflict(new
            {
                error = "The stack is empty."
            });
        }

        stack.Pop();

        SaveStack(stack);

        return Ok(CreateResponse(stack));
    }

    private async Task<Stack<int>> LoadStackAsync(
        CancellationToken cancellationToken)
    {
        await HttpContext.Session.LoadAsync(cancellationToken);

        var serializedStack =
            HttpContext.Session.GetString(StackKey);

        if (serializedStack is null)
        {
            var emptyStack = new Stack<int>();

            SaveStack(emptyStack);

            return emptyStack;
        }

        var values =
            JsonSerializer.Deserialize<int[]>(serializedStack)
            ?? Array.Empty<int>();

        return new Stack<int>(values);
    }

    private void SaveStack(Stack<int> stack)
    {
        var bottomToTop = stack.Reverse().ToArray();

        HttpContext.Session.SetString(
            StackKey,
            JsonSerializer.Serialize(bottomToTop));
    }

    private StackResponse CreateResponse(Stack<int> stack)
    {
        var result = _applicationResult.Value;
        var top = stack.Count == 0 ? 0 : stack.Peek();

        return new StackResponse((long)result + top);
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