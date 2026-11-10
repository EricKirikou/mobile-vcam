using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using MobileVirtualCamera.Desktop.Models;
using Microsoft.Extensions.Logging;

namespace MobileVirtualCamera.Desktop.Services;

/// <summary>
/// Generic HTTP client wrapper for communicating with the backend REST API.
/// Automatically attaches the JWT Bearer token from the AuthService.
/// </summary>
public class ApiService : IApiService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ApiService> _logger;

    private static readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true
    };

    public ApiService(HttpClient httpClient, ILogger<ApiService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public void SetAuthToken(string token)
    {
        _httpClient.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
    }

    public void SetDeviceId(string deviceId)
    {
        _httpClient.DefaultRequestHeaders.Remove("X-Device-ID");
        _httpClient.DefaultRequestHeaders.Add("X-Device-ID", deviceId);
    }

    public async Task<TResponse?> GetAsync<TResponse>(string endpoint)
    {
        _logger.LogDebug("GET {Endpoint}", endpoint);
        var response = await _httpClient.GetAsync(endpoint);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<TResponse>(_jsonOptions);
    }

    public async Task<TResponse?> PostAsync<TResponse>(string endpoint, object? body = null)
    {
        _logger.LogDebug("POST {Endpoint}", endpoint);
        HttpContent content = body is null
            ? new StringContent("{}", System.Text.Encoding.UTF8, "application/json")
            : JsonContent.Create(body, options: _jsonOptions);

        var response = await _httpClient.PostAsync(endpoint, content);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<TResponse>(_jsonOptions);
    }

    public async Task<TResponse?> PatchAsync<TResponse>(string endpoint, object body)
    {
        _logger.LogDebug("PATCH {Endpoint}", endpoint);
        var content = JsonContent.Create(body, options: _jsonOptions);
        var response = await _httpClient.PatchAsync(endpoint, content);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<TResponse>(_jsonOptions);
    }

    public async Task DeleteAsync(string endpoint)
    {
        _logger.LogDebug("DELETE {Endpoint}", endpoint);
        var response = await _httpClient.DeleteAsync(endpoint);
        response.EnsureSuccessStatusCode();
    }
}

public interface IApiService
{
    void SetAuthToken(string token);
    void SetDeviceId(string deviceId);
    Task<TResponse?> GetAsync<TResponse>(string endpoint);
    Task<TResponse?> PostAsync<TResponse>(string endpoint, object? body = null);
    Task<TResponse?> PatchAsync<TResponse>(string endpoint, object body);
    Task DeleteAsync(string endpoint);
}
