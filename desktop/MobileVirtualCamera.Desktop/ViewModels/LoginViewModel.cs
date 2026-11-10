using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MobileVirtualCamera.Desktop.Models;
using MobileVirtualCamera.Desktop.Services;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.ViewModels;

public partial class LoginViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly MainViewModel _mainVm;

    [ObservableProperty] private string _email = string.Empty;
    [ObservableProperty] private string _password = string.Empty;
    [ObservableProperty] private string _errorMessage = string.Empty;
    [ObservableProperty] private bool _isLoading;
    [ObservableProperty] private bool _rememberMe = true;

    public LoginViewModel(IAuthService authService, MainViewModel mainVm)
    {
        _authService = authService;
        _mainVm = mainVm;
    }

    [RelayCommand]
    private async Task LoginAsync()
    {
        if (string.IsNullOrWhiteSpace(Email) || string.IsNullOrWhiteSpace(Password))
        {
            ErrorMessage = "Email and password are required.";
            return;
        }

        IsLoading = true;
        ErrorMessage = string.Empty;

        try
        {
            var result = await _authService.LoginAsync(new LoginRequest
            {
                Email = Email,
                Password = Password,
                DeviceId = AppSettings.DesktopDeviceId,
                DeviceName = AppSettings.DesktopDeviceName,
                Platform = "windows",
                DeviceType = "desktop"
            });

            _mainVm.OnLoginSuccess(result.User);
        }
        catch (System.Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task ContinueAsGuestAsync()
    {
        await _mainVm.ContinueAsGuestAsync();
    }

    [RelayCommand]
    private async Task GoogleSignInAsync()
    {
        // In production: launch system browser OAuth2 flow and capture redirect
        ErrorMessage = "Google Sign-In: Open browser OAuth flow not yet implemented in this build.";
        await Task.CompletedTask;
    }
}
