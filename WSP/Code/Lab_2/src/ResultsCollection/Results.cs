using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text.Json;

namespace Bstu.Results.Collection;

public sealed record ResultItem(int Key, string Value);

public sealed class ResultsOptions
{
    public string FilePath { get; set; } = "App_Data/results.json";
    public TimeSpan LockTimeout { get; set; } = TimeSpan.FromSeconds(30);
}

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddResultsCollection(
        this IServiceCollection services,
        Action<ResultsOptions> configure)
    {
        services.Configure(configure);
        services.AddTransient<Results>();

        return services;
    }
}

public sealed class Results
{
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> Gates =
        new(OperatingSystem.IsWindows()
            ? StringComparer.OrdinalIgnoreCase
            : StringComparer.Ordinal);

    private static readonly JsonSerializerOptions Json =
        new(JsonSerializerDefaults.Web)
        {
            WriteIndented = true
        };

    private readonly string _path;
    private readonly TimeSpan _timeout;
    private readonly SemaphoreSlim _gate;

    public Results(IOptions<ResultsOptions> options)
    {
        _path = Path.GetFullPath(options.Value.FilePath);
        _timeout = options.Value.LockTimeout;

        _gate = Gates.GetOrAdd(
            _path,
            _ => new SemaphoreSlim(1, 1));

        Directory.CreateDirectory(
            Path.GetDirectoryName(_path)!);
    }

    public Task<ResultItem[]> GetAllAsync(
        CancellationToken ct = default) =>
        AccessAsync(
            state => (
                state.Items.OrderBy(x => x.Key).ToArray(),
                false),
            ct);

    public Task<ResultItem?> GetAsync(
        int key,
        CancellationToken ct = default) =>
        AccessAsync(
            state => (
                state.Items.Find(x => x.Key == key),
                false),
            ct);

    public Task<ResultItem> AddAsync(
        string value,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(value);

        return AccessAsync(state =>
        {
            var item = new ResultItem(
                checked(state.LastKey + 1),
                value);

            state.LastKey = item.Key;
            state.Items.Add(item);

            return (item, true);
        }, ct);
    }

    public Task<ResultItem?> UpdateAsync(
        int key,
        string value,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(value);

        return AccessAsync<ResultItem?>(state =>
        {
            var index = state.Items.FindIndex(x => x.Key == key);

            if (index < 0)
                return (null, false);

            var item = new ResultItem(key, value);
            state.Items[index] = item;

            return (item, true);
        }, ct);
    }

    public Task<ResultItem?> DeleteAsync(
        int key,
        CancellationToken ct = default) =>
        AccessAsync<ResultItem?>(state =>
        {
            var item = state.Items.Find(x => x.Key == key);

            if (item is null)
                return (null, false);

            state.Items.Remove(item);

            return (item, true);
        }, ct);

    private async Task<T> AccessAsync<T>(
        Func<CollectionState, (T Value, bool Changed)> action,
        CancellationToken ct)
    {
        await _gate.WaitAsync(ct);

        try
        {
           
            using var file = await OpenLockedAsync(ct);

            var fresh = file.Length == 0;

            var state = fresh
                ? new CollectionState()
                : await JsonSerializer.DeserializeAsync<CollectionState>(
                      file, Json, ct)
                  ?? throw new InvalidDataException(
                      "The results file contains JSON null.");

            Validate(state);

            var (value, changed) = action(state);

            if (fresh || changed)
            {
                
                var bytes = JsonSerializer.SerializeToUtf8Bytes(state, Json);

                file.Position = 0;
                file.Write(bytes);
                file.SetLength(bytes.Length);
                file.Flush(flushToDisk: true);
            }

            return value;
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<FileStream> OpenLockedAsync(
        CancellationToken ct)
    {
        var timer = Stopwatch.StartNew();

        while (true)
        {
            ct.ThrowIfCancellationRequested();

            try
            {
                return new FileStream(
                    _path,
                    FileMode.OpenOrCreate,
                    FileAccess.ReadWrite,
                    FileShare.None,
                    4096,
                    FileOptions.Asynchronous);
            }
            catch (IOException ex) when (
                IsSharingViolation(ex) &&
                timer.Elapsed < _timeout)
            {
                await Task.Delay(20, ct);
            }
        }
    }

    private static bool IsSharingViolation(IOException ex) =>
        (ex.HResult & 0xffff) is 11 or 32 or 33;

    private static void Validate(CollectionState state)
    {
        if (state.LastKey < 0 ||
            state.Items is null ||
            state.Items.Any(x =>
                x is null ||
                x.Key <= 0 ||
                x.Key > state.LastKey ||
                x.Value is null) ||
            state.Items.Select(x => x.Key).Distinct().Count()
                != state.Items.Count)
        {
            throw new InvalidDataException(
                "The results JSON file has an invalid collection or counter.");
        }
    }

    private sealed class CollectionState
    {
        public CollectionState() { }

        public int LastKey { get; set; }

        public List<ResultItem> Items { get; set; } = [];
    }
}