namespace JSONRPCServer.Services;

public sealed class CalculatorService
{
    public double SUM(double x, double y)
    {
        return EnsureFinite(x + y);
    }

    public double SUB(double x, double y)
    {
        return EnsureFinite(x - y);
    }

    public double MUL(double x, double y)
    {
        return EnsureFinite(x * y);
    }

    public double DIV(double x, double y)
    {
        if (y == 0)
        {
            throw new DivideByZeroException(
                "Division by zero is not allowed.");
        }

        return EnsureFinite(x / y);
    }

    public int FACT(int x)
    {
        if (x < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(x),
                "Factorial requires a non-negative integer.");
        }

        if (x > 12)
        {
            throw new OverflowException(
                "Factorial exceeds the Int32 range. Maximum x is 12.");
        }

        var result = 1;

        checked
        {
            for (var i = 2; i <= x; i++)
            {
                result *= i;
            }
        }

        return result;
    }

    private static double EnsureFinite(double result)
    {
        if (!double.IsFinite(result))
        {
            throw new OverflowException(
                "The result exceeds the finite Double range.");
        }

        return result;
    }
}