using System.Threading;

namespace WS01_02.Services;

public sealed class ApplicationResult
{
    private int _value;

    public int Value
    {
        get => Volatile.Read(ref _value);
        set => Interlocked.Exchange(ref _value, value);
    }
}