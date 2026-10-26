using Grpc.Core;

namespace gRPCServer01.Services;

public sealed class CalculatorService : Calculator.CalculatorBase
{
    public override Task<DoubleResponse> SUM(
        BinaryOperationRequest request,
        ServerCallContext context)
    {
        return Task.FromResult(new DoubleResponse
        {
            Result = request.X + request.Y
        });
    }

    public override Task<DoubleResponse> SUB(
        BinaryOperationRequest request,
        ServerCallContext context)
    {
        return Task.FromResult(new DoubleResponse
        {
            Result = request.X - request.Y
        });
    }

    public override Task<DoubleResponse> MUL(
        BinaryOperationRequest request,
        ServerCallContext context)
    {
        return Task.FromResult(new DoubleResponse
        {
            Result = request.X * request.Y
        });
    }

    public override Task<DoubleResponse> DIV(
        BinaryOperationRequest request,
        ServerCallContext context)
    {
        if (request.Y == 0)
        {
            throw new RpcException(new Status(
                StatusCode.InvalidArgument,
                "Division by zero is not allowed."));
        }

        return Task.FromResult(new DoubleResponse
        {
            Result = request.X / request.Y
        });
    }

    public override Task<IntResponse> FACT(
        FactorialRequest request,
        ServerCallContext context)
    {
        if (request.X < 0)
        {
            throw new RpcException(new Status(
                StatusCode.InvalidArgument,
                "Factorial is defined only for non-negative integers."));
        }

        int result = 1;

        try
        {
            for (int i = 2; i <= request.X; i++)
            {
                result = checked(result * i);
            }
        }
        catch (OverflowException)
        {
            throw new RpcException(new Status(
                StatusCode.OutOfRange,
                "Factorial exceeds the maximum value of Int32."));
        }

        return Task.FromResult(new IntResponse
        {
            Result = result
        });
    }
}