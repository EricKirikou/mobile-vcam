using System.Threading.Tasks;
using System.Net.Http;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using System;

namespace MobileVirtualCamera.Desktop.Services;

public class UpdateService : IUpdateService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<UpdateService> _logger;

    public UpdateService(HttpClient httpClient, ILogger<UpdateService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<bool> CheckForUpdatesAsync()
    {
        try
        {
            // Replace with real update server endpoint
            var json = await _httpClient.GetStringAsync("https://releases.virtualcam.app/windows/latest.json");
            using var doc = JsonDocument.Parse(json);
            var latestVersion = doc.RootElement.GetProperty("version").GetString();
            var current = new Version(AppSettings.AppVersion);
            var latest = new Version(latestVersion ?? AppSettings.AppVersion);
            return latest > current;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Update check failed");
            return false;
        }
    }
}

public interface IUpdateService
{
    Task<bool> CheckForUpdatesAsync();
}

public class SettingsService : ISettingsService
{
    private readonly IApiService _apiService;
    public SettingsService(IApiService apiService) => _apiService = apiService;

    public async Task<object?> GetSettingsAsync()
    {
        var response = await _apiService.GetAsync<object>("/api/settings");
        return response;
    }

    public async Task SaveSettingsAsync(object settings)
    {
        await _apiService.PatchAsync<object>("/api/settings", settings);
    }
}

public interface ISettingsService
{
    Task<object?> GetSettingsAsync();
    Task SaveSettingsAsync(object settings);
}
