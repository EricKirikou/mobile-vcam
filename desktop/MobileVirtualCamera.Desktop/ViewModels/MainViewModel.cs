using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MobileVirtualCamera.Desktop.Models;
using MobileVirtualCamera.Desktop.Services;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.ViewModels;

/// <summary>
/// Main application shell ViewModel managing navigation and global state.
/// Supports both Authenticated (Cloud) and Guest (Local Network) modes.
/// </summary>
public partial class MainViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly ISignalingService _signalingService;
    private readonly IVirtualCameraService _virtualCameraService;
    private readonly ILogger<MainViewModel> _logger;

    [ObservableProperty]
    private ObservableObject? _currentPage;

    [ObservableProperty]
    private bool _isAuthenticated;

    [ObservableProperty]
    private bool _isGuest = true;

    [ObservableProperty]
    private UserModel? _currentUser;

    [ObservableProperty]
    private string _statusMessage = "Ready";

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private AppTheme _currentTheme = AppTheme.Dark;

    public MainViewModel(
        IAuthService authService,
        ISignalingService signalingService,
        IVirtualCameraService virtualCameraService,
        ILogger<MainViewModel> logger)
    {
        _authService = authService;
        _signalingService = signalingService;
        _virtualCameraService = virtualCameraService;
        _logger = logger;
    }

    public async Task InitializeAsync()
    {
        IsLoading = true;
        StatusMessage = "Starting services...";

        try
        {
            // Attempt to restore session from stored token
            var session = await _authService.TryRestoreSessionAsync();
            if (session is not null)
            {
                CurrentUser = session.User;
                IsAuthenticated = true;
                IsGuest = false;
                StatusMessage = $"Welcome back, {session.User.Name}";
                await NavigateToDashboardAsync();
            }
            else
            {
                // Default to Guest Mode so user is never locked behind a login screen!
                await ContinueAsGuestAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not reach auth server, entering Local Guest Mode");
            await ContinueAsGuestAsync();
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    public async Task ContinueAsGuestAsync()
    {
        CurrentUser = new UserModel
        {
            Name = "Guest User",
            Email = "Local Wi-Fi / LAN",
            Role = "guest"
        };
        IsAuthenticated = false;
        IsGuest = true;
        StatusMessage = "Running in Local Guest Mode (No Cloud Account Needed)";
        await NavigateToDashboardAsync();
    }

    [RelayCommand]
    public Task NavigateToLoginAsync()
    {
        var loginVm = App.Services.GetService(typeof(LoginViewModel)) as LoginViewModel;
        CurrentPage = loginVm;
        return Task.CompletedTask;
    }

    [RelayCommand]
    public async Task NavigateToDashboardAsync()
    {
        var dashVm = App.Services.GetService(typeof(DashboardViewModel)) as DashboardViewModel;
        if (dashVm is not null)
        {
            CurrentPage = dashVm;
            await dashVm.LoadAsync();
        }
    }

    [RelayCommand]
    public async Task NavigateToPairingAsync()
    {
        var pairingVm = App.Services.GetService(typeof(PairingViewModel)) as PairingViewModel;
        if (pairingVm is not null)
        {
            CurrentPage = pairingVm;
            // Auto generate or refresh pairing code and local network listener on visit
            await pairingVm.GeneratePairingCommand.ExecuteAsync(null);
        }
    }

    [RelayCommand]
    public async Task NavigateToSettingsAsync()
    {
        var settingsVm = App.Services.GetService(typeof(SettingsViewModel)) as SettingsViewModel;
        if (settingsVm is not null)
        {
            CurrentPage = settingsVm;
            await settingsVm.LoadAsync();
        }
    }

    public void NavigateToDeviceDetail(DeviceModel device)
    {
        var detailVm = App.Services.GetService(typeof(DeviceDetailViewModel)) as DeviceDetailViewModel;
        if (detailVm is not null)
        {
            detailVm.LoadDevice(device);
            CurrentPage = detailVm;
        }
    }

    public void OnLoginSuccess(UserModel user)
    {
        CurrentUser = user;
        IsAuthenticated = true;
        IsGuest = false;
        StatusMessage = $"Logged in as {user.Name}";
        _ = NavigateToDashboardAsync();
    }

    [RelayCommand]
    public async Task LogoutAsync()
    {
        if (IsAuthenticated)
        {
            await _authService.LogoutAsync();
        }
        await ContinueAsGuestAsync();
    }
}
