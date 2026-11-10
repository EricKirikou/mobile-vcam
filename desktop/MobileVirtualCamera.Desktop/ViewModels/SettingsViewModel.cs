using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MobileVirtualCamera.Desktop.Services;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.ViewModels;

/// <summary>
/// ViewModel for the Settings page — manages app preferences, camera defaults,
/// server configuration, and virtual camera driver options.
/// </summary>
public partial class SettingsViewModel : ObservableObject
{
    private readonly ISettingsService _settingsService;
    private readonly IVirtualCameraService _virtualCameraService;
    private readonly ILogger<SettingsViewModel> _logger;

    // ── Server ─────────────────────────────────────────────────────────────
    [ObservableProperty]
    private string _serverUrl = "http://localhost:3000";

    [ObservableProperty]
    private bool _useSecureConnection;

    // ── Camera Defaults ─────────────────────────────────────────────────────
    [ObservableProperty]
    private string _selectedResolution = "4K (3840x2160)";

    [ObservableProperty]
    private int _selectedFps = 60;

    [ObservableProperty]
    private int _selectedBitrateKbps = 25000;

    [ObservableProperty]
    private string _selectedCodec = "H.265 (HEVC)";

    [ObservableProperty]
    private bool _enableHardwareEncoding = true;

    [ObservableProperty]
    private bool _enableLowLatencyMode;

    // ── Virtual Camera Driver ───────────────────────────────────────────────
    [ObservableProperty]
    private bool _virtualCameraActive;

    [ObservableProperty]
    private string _virtualCameraDriverStatus = "Checking...";

    // ── Notifications ───────────────────────────────────────────────────────
    [ObservableProperty]
    private bool _showSystemNotifications = true;

    [ObservableProperty]
    private bool _showBatteryWarnings = true;

    [ObservableProperty]
    private int _batteryWarningThreshold = 20;

    // ── UI ──────────────────────────────────────────────────────────────────
    [ObservableProperty]
    private bool _isSaving;

    [ObservableProperty]
    private string _statusMessage = string.Empty;

    [ObservableProperty]
    private bool _hasUnsavedChanges;

    public ObservableCollection<string> ResolutionOptions { get; } = new(new[]
    {
        "4K (3840x2160)",
        "1440p (2560x1440)",
        "1080p (1920x1080)",
        "720p (1280x720)",
        "480p (854x480)"
    });

    public ObservableCollection<int> FpsOptions { get; } = new(new[] { 24, 30, 48, 60 });

    public ObservableCollection<string> CodecOptions { get; } = new(new[]
    {
        "H.265 (HEVC)",
        "H.264 (AVC)",
        "VP9",
        "AV1"
    });

    public SettingsViewModel(
        ISettingsService settingsService,
        IVirtualCameraService virtualCameraService,
        ILogger<SettingsViewModel> logger)
    {
        _settingsService = settingsService;
        _virtualCameraService = virtualCameraService;
        _logger = logger;

        PropertyChanged += (_, _) => HasUnsavedChanges = true;
    }

    public async Task LoadAsync()
    {
        try
        {
            var driverActive = _virtualCameraService.IsRunning;
            VirtualCameraActive = driverActive;
            VirtualCameraDriverStatus = driverActive ? "✓ Running" : "Stopped";

            StatusMessage = string.Empty;
            HasUnsavedChanges = false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load settings");
            StatusMessage = "Failed to load settings.";
        }
    }

    [RelayCommand]
    private async Task SaveSettingsAsync()
    {
        IsSaving = true;
        StatusMessage = "Saving…";
        try
        {
            var payload = new
            {
                serverUrl = ServerUrl,
                useSecureConnection = UseSecureConnection,
                camera = new
                {
                    resolution = SelectedResolution,
                    fps = SelectedFps,
                    bitrateKbps = SelectedBitrateKbps,
                    codec = SelectedCodec,
                    enableHardwareEncoding = EnableHardwareEncoding,
                    enableLowLatencyMode = EnableLowLatencyMode
                },
                notifications = new
                {
                    showSystemNotifications = ShowSystemNotifications,
                    showBatteryWarnings = ShowBatteryWarnings,
                    batteryWarningThreshold = BatteryWarningThreshold
                }
            };

            await _settingsService.SaveSettingsAsync(payload);
            StatusMessage = "✓ Settings saved successfully.";
            HasUnsavedChanges = false;
            _logger.LogInformation("Settings saved.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save settings");
            StatusMessage = $"Error saving settings: {ex.Message}";
        }
        finally
        {
            IsSaving = false;
        }
    }

    [RelayCommand]
    private async Task ResetToDefaultsAsync()
    {
        ServerUrl = "http://localhost:3000";
        UseSecureConnection = false;
        SelectedResolution = "4K (3840x2160)";
        SelectedFps = 60;
        SelectedBitrateKbps = 25000;
        SelectedCodec = "H.265 (HEVC)";
        EnableHardwareEncoding = true;
        EnableLowLatencyMode = false;
        ShowSystemNotifications = true;
        ShowBatteryWarnings = true;
        BatteryWarningThreshold = 20;

        await SaveSettingsAsync();
        StatusMessage = "✓ Defaults restored.";
    }

    [RelayCommand]
    private async Task ToggleVirtualCameraAsync()
    {
        try
        {
            if (VirtualCameraActive)
            {
                await _virtualCameraService.StopVirtualCameraAsync();
                VirtualCameraActive = false;
                VirtualCameraDriverStatus = "Stopped";
            }
            else
            {
                await _virtualCameraService.StartVirtualCameraAsync(3840, 2160, 60);
                VirtualCameraActive = true;
                VirtualCameraDriverStatus = "✓ Running";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to toggle virtual camera");
            StatusMessage = $"Virtual camera error: {ex.Message}";
        }
    }
}
