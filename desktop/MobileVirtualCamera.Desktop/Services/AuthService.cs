using Microsoft.Extensions.Logging;
using MobileVirtualCamera.Desktop.Models;
using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.Services;

/// <summary>
/// Handles login, token storage/refresh, and session restoration.
/// Tokens are persisted securely using Windows DPAPI-encrypted local files.
/// </summary>
public class AuthService : IAuthService
{
    private readonly IApiService _apiService;
    private readonly ILogger<AuthService> _logger;

    private static readonly string _tokenFilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "MobileVirtualCamera", "session.dat");

    private AuthTokens? _currentTokens;
    private UserModel? _currentUser;

    public AuthService(IApiService apiService, ILogger<AuthService> logger)
    {
        _apiService = apiService;
        _logger = logger;
    }

    public async Task<LoginResult> LoginAsync(LoginRequest request)
    {
        var response = await _apiService.PostAsync<ApiResponse<LoginResult>>(
            "/api/auth/login", request);

        if (response?.Data is null)
            throw new Exception("Login failed: empty response from server.");

        _currentTokens = response.Data.Tokens;
        _currentUser = response.Data.User;

        // Store tokens and configure http client
        await SaveSessionAsync(response.Data.Tokens);
        _apiService.SetAuthToken(_currentTokens.AccessToken);
        _apiService.SetDeviceId(AppSettings.DesktopDeviceId);

        return response.Data;
    }

    public async Task<LoginResult?> TryRestoreSessionAsync()
    {
        try
        {
            var tokens = await LoadSessionAsync();
            if (tokens is null) return null;

            // Try to refresh the access token
            var refreshed = await _apiService.PostAsync<ApiResponse<AuthTokens>>(
                "/api/auth/refresh", new { refreshToken = tokens.RefreshToken });

            if (refreshed?.Data is null) return null;

            _currentTokens = refreshed.Data;
            await SaveSessionAsync(_currentTokens);
            _apiService.SetAuthToken(_currentTokens.AccessToken);
            _apiService.SetDeviceId(AppSettings.DesktopDeviceId);

            // Fetch profile
            var profile = await _apiService.GetAsync<ApiResponse<ProfileResult>>("/api/auth/profile");
            _currentUser = profile?.Data?.User;

            return new LoginResult { User = _currentUser!, Tokens = _currentTokens };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Session restore failed — user must log in again");
            await ClearSessionAsync();
            return null;
        }
    }

    public async Task LogoutAsync()
    {
        try
        {
            await _apiService.PostAsync<object>("/api/auth/logout");
        }
        catch { /* Best effort */ }
        finally
        {
            _currentTokens = null;
            _currentUser = null;
            await ClearSessionAsync();
        }
    }

    public string? GetAccessToken() => _currentTokens?.AccessToken;
    public UserModel? GetCurrentUser() => _currentUser;

    private async Task SaveSessionAsync(AuthTokens tokens)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_tokenFilePath)!);
            var json = JsonSerializer.Serialize(tokens);
            // Encrypt with Windows DPAPI (machine-local, user-scoped)
            var plainBytes = System.Text.Encoding.UTF8.GetBytes(json);
            var encrypted = System.Security.Cryptography.ProtectedData.Protect(
                plainBytes, null, System.Security.Cryptography.DataProtectionScope.CurrentUser);
            await File.WriteAllBytesAsync(_tokenFilePath, encrypted);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not persist session tokens");
        }
    }

    private async Task<AuthTokens?> LoadSessionAsync()
    {
        try
        {
            if (!File.Exists(_tokenFilePath)) return null;
            var encrypted = await File.ReadAllBytesAsync(_tokenFilePath);
            var plainBytes = System.Security.Cryptography.ProtectedData.Unprotect(
                encrypted, null, System.Security.Cryptography.DataProtectionScope.CurrentUser);
            var json = System.Text.Encoding.UTF8.GetString(plainBytes);
            return JsonSerializer.Deserialize<AuthTokens>(json);
        }
        catch
        {
            return null;
        }
    }

    private Task ClearSessionAsync()
    {
        try { File.Delete(_tokenFilePath); } catch { }
        return Task.CompletedTask;
    }
}

public interface IAuthService
{
    Task<LoginResult> LoginAsync(LoginRequest request);
    Task<LoginResult?> TryRestoreSessionAsync();
    Task LogoutAsync();
    string? GetAccessToken();
    UserModel? GetCurrentUser();
}
