using System.Text.Json;
using JSONRPCServer.Services;
using Microsoft.AspNetCore.Mvc;

namespace JSONRPCServer.Controllers;

[ApiController]
[Route("rpc")]
public sealed class JsonRpcController(
    JsonRpcDispatcher dispatcher) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Post(CancellationToken cancellationToken)
    {
        JsonDocument document;

        try
        {
            document = await JsonDocument.ParseAsync(
                Request.Body,
                cancellationToken: cancellationToken);
        }
        catch (JsonException)
        {
            return new JsonResult(
                JsonRpcDispatcher.CreateError(
                    null,
                    -32700,
                    "Parse error"));
        }

        using (document)
        {
            var response = dispatcher.Handle(document.RootElement);

            if (response is null)
            {
                return NoContent();
            }

            return new JsonResult(response);
        }
    }
}