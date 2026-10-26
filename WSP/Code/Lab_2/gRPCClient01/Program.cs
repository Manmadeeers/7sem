using System.Globalization;
using Grpc.Core;
using Grpc.Net.Client;
using gRPCServer01;

const string serverAddress = "http://localhost:5000";

using var channel = GrpcChannel.ForAddress(serverAddress);

var client = new Calculator.CalculatorClient(channel);

Console.WriteLine("gRPCClient01");
Console.WriteLine($"Server: {serverAddress}");

while (true)
{
    Console.WriteLine();
    Console.WriteLine("1. SUM");
    Console.WriteLine("2. SUB");
    Console.WriteLine("3. MUL");
    Console.WriteLine("4. DIV");
    Console.WriteLine("5. FACT");
    Console.WriteLine("0. Exit");
    Console.Write("Choose an operation: ");

    string? operation = Console.ReadLine()?.Trim();

    if (operation is null or "0")
    {
        break;
    }

    if (operation is not ("1" or "2" or "3" or "4" or "5"))
    {
        Console.WriteLine("Invalid operation. Choose a number from 0 to 5.");
        continue;
    }

    try
    {
        if (operation == "5")
        {
            int x = ReadInt("x");

            var response = await client.FACTAsync(
                new FactorialRequest
                {
                    X = x
                },
                deadline: DateTime.UtcNow.AddSeconds(5));

            Console.WriteLine($"FACT({x}) = {response.Result}");

            continue;
        }

        double first = ReadDouble("x");
        double second = ReadDouble("y");

        var request = new BinaryOperationRequest
        {
            X = first,
            Y = second
        };

        DateTime deadline = DateTime.UtcNow.AddSeconds(5);

        DoubleResponse result = operation switch
        {
            "1" => await client.SUMAsync(request, deadline: deadline),
            "2" => await client.SUBAsync(request, deadline: deadline),
            "3" => await client.MULAsync(request, deadline: deadline),
            "4" => await client.DIVAsync(request, deadline: deadline),
            _ => throw new InvalidOperationException()
        };

        Console.WriteLine($"Result: {result.Result}");
    }
    catch (RpcException exception)
    {
        Console.WriteLine($"gRPC error: {exception.StatusCode}");
        Console.WriteLine($"Message: {exception.Status.Detail}");

        if (exception.StatusCode == StatusCode.Unavailable)
        {
            Console.WriteLine(
                $"Check that gRPCServer01 is running at {serverAddress}.");
        }
    }
    catch (EndOfStreamException)
    {
        break;
    }
}

static double ReadDouble(string name)
{
    while (true)
    {
        Console.Write($"Enter {name}: ");

        string? input = Console.ReadLine();

        if (input is null)
        {
            throw new EndOfStreamException();
        }

        input = input.Trim().Replace(',', '.');

        if (double.TryParse(
                input,
                NumberStyles.Float,
                CultureInfo.InvariantCulture,
                out double value)
            && double.IsFinite(value))
        {
            return value;
        }

        Console.WriteLine(
            "Invalid number. Enter a finite number, for example 10 or 2.5.");
    }
}

static int ReadInt(string name)
{
    while (true)
    {
        Console.Write($"Enter {name}: ");

        string? input = Console.ReadLine();

        if (input is null)
        {
            throw new EndOfStreamException();
        }

        if (int.TryParse(
                input,
                NumberStyles.Integer,
                CultureInfo.InvariantCulture,
                out int value))
        {
            return value;
        }

        Console.WriteLine("Invalid number. Enter a 32-bit integer.");
    }
}