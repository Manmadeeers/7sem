using System.Text.Json;

namespace JSONRPCServer.Services;

public sealed class JsonRpcDispatcher(
    CalculatorService calculator,
    ILogger<JsonRpcDispatcher> logger)
{
    public object? Handle(JsonElement root)
    {
        if (root.ValueKind != JsonValueKind.Array)
        {
            return ProcessRequest(root);
        }

        if (root.GetArrayLength() == 0)
        {
            return CreateError(
                null,
                -32600,
                "Invalid Request");
        }

        var responses = new List<object>();

        foreach (var request in root.EnumerateArray())
        {
            var response = ProcessRequest(request);

            if (response is not null)
            {
                responses.Add(response);
            }
        }

        return responses.Count == 0 ? null : responses;
    }

    public static object CreateError(
        JsonElement? id,
        int code,
        string message)
    {
        return new
        {
            jsonrpc = "2.0",
            error = new
            {
                code,
                message
            },
            id = id?.Clone()
        };
    }

    private object? ProcessRequest(JsonElement request)
    {
        if (request.ValueKind != JsonValueKind.Object)
        {
            return CreateError(
                null,
                -32600,
                "Invalid Request");
        }

        var hasId = request.TryGetProperty("id", out var id);

        if (hasId &&
            id.ValueKind is not (
                JsonValueKind.String or
                JsonValueKind.Number or
                JsonValueKind.Null))
        {
            return CreateError(
                null,
                -32600,
                "Invalid Request");
        }

        if (!request.TryGetProperty("jsonrpc", out var version) ||
            version.ValueKind != JsonValueKind.String ||
            version.GetString() != "2.0" ||
            !request.TryGetProperty("method", out var method) ||
            method.ValueKind != JsonValueKind.String)
        {
            return CreateError(
                null,
                -32600,
                "Invalid Request");
        }

        if (request.TryGetProperty("params", out var parameters) &&
            parameters.ValueKind is not (
                JsonValueKind.Array or
                JsonValueKind.Object))
        {
            return CreateError(
                null,
                -32600,
                "Invalid Request");
        }

        JsonElement? responseId = hasId ? id.Clone() : null;

        try
        {
            object result;

            switch (method.GetString())
            {
                case "SUM":
                case "SUB":
                case "MUL":
                case "DIV":
                {
                    var arguments = ReadArguments(parameters, "x", "y");

                    var x = ReadDouble(arguments[0], "x");
                    var y = ReadDouble(arguments[1], "y");

                    result = method.GetString() switch
                    {
                        "SUM" => calculator.SUM(x, y),
                        "SUB" => calculator.SUB(x, y),
                        "MUL" => calculator.MUL(x, y),
                        "DIV" => calculator.DIV(x, y),
                        _ => throw new InvalidOperationException()
                    };

                    break;
                }

                case "FACT":
                {
                    var arguments = ReadArguments(parameters, "x");
                    var x = ReadInt(arguments[0], "x");

                    result = calculator.FACT(x);

                    break;
                }

                default:
                    return hasId
                        ? CreateError(
                            responseId,
                            -32601,
                            "Method not found")
                        : null;
            }

            if (!hasId)
            {
                return null;
            }

            return new
            {
                jsonrpc = "2.0",
                result,
                id = responseId
            };
        }
        catch (DivideByZeroException exception)
        {
            return hasId
                ? CreateError(responseId, 1001, exception.Message)
                : null;
        }
        catch (OverflowException exception)
        {
            return hasId
                ? CreateError(responseId, 1002, exception.Message)
                : null;
        }
        catch (ArgumentException exception)
        {
            return hasId
                ? CreateError(responseId, -32602, exception.Message)
                : null;
        }
        catch (Exception exception)
        {
            logger.LogError(
                exception,
                "Failed to execute JSON-RPC method {Method}.",
                method.GetString());

            return hasId
                ? CreateError(responseId, -32603, "Internal error")
                : null;
        }
    }

    private static JsonElement[] ReadArguments(
        JsonElement parameters,
        params string[] names)
    {
        var arguments = new JsonElement[names.Length];

        if (parameters.ValueKind == JsonValueKind.Array)
        {
            if (parameters.GetArrayLength() != names.Length)
            {
                throw new ArgumentException(
                    $"Expected exactly {names.Length} parameters.");
            }

            for (var i = 0; i < names.Length; i++)
            {
                arguments[i] = parameters[i];
            }

            return arguments;
        }

        if (parameters.ValueKind == JsonValueKind.Object)
        {
            if (parameters.EnumerateObject().Count() != names.Length)
            {
                throw new ArgumentException(
                    $"Expected exactly {names.Length} parameters.");
            }

            for (var i = 0; i < names.Length; i++)
            {
                if (!parameters.TryGetProperty(names[i], out arguments[i]))
                {
                    throw new ArgumentException(
                        $"Missing parameter '{names[i]}'.");
                }
            }

            return arguments;
        }

        throw new ArgumentException(
            "Parameters must be supplied as an array or an object.");
    }

    private static double ReadDouble(JsonElement value, string name)
    {
        if (value.ValueKind != JsonValueKind.Number ||
            !value.TryGetDouble(out var result) ||
            !double.IsFinite(result))
        {
            throw new ArgumentException(
                $"Parameter '{name}' must be a finite Double number.");
        }

        return result;
    }

    private static int ReadInt(JsonElement value, string name)
    {
        if (value.ValueKind != JsonValueKind.Number ||
            !value.TryGetInt32(out var result))
        {
            throw new ArgumentException(
                $"Parameter '{name}' must be an Int32 integer.");
        }

        return result;
    }
}