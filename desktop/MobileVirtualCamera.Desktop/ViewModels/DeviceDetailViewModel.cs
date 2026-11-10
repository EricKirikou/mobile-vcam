using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MobileVirtualCamera.Desktop.Models;
using MobileVirtualCamera.Desktop.Services;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.ViewModels;

/// <summary>
/// ViewModel for the Device Detail page — shows live telemetry, camera
/// capabilities, and streaming controls for a single paired device.
/// </summary>
public partial class DeviceDetailViewModel : ObservableObject
{
    private readonly IDeviceService _deviceService;
    private readonly IVirtualCameraService _virtualCameraService;
    private readonly ILogger<DeviceDetailViewModel> _logger;

    private CancellationTokenSource? _telemetryCts;

    // ── Identity ────────────────────────────────────────────────────────────
    [ObservableProperty]
    private string _deviceId = string.Empty;

    [ObservableProperty]
    private string _deviceName = string.Empty;

    [ObservableProperty]
    private string _platform = string.Empty;

    [ObservableProperty]
    private string _model = string.Empty;

    [ObservableProperty]
    private string _deviceType = string.Empty;

    [ObservableProperty]
    private string _status = "offline";

    // ── Telemetry ───────────────────────────────────────────────────────────
    [ObservableProperty]
    private int _batteryLevel = 100;

    [ObservableProperty]
    private bool _isCharging;

    [ObservableProperty]
    private double _batteryTemperatureC;

    [ObservableProperty]
    private string _networkType = "wifi";

    // ── Camera Capabilities ─────────────────────────────────────────────────
    [ObservableProperty]
    private bool _hasFrontCamera;

    [ObservableProperty]
    private bool _hasBackCamera;

    [ObservableProperty]
    private string _maxResolution = "4K";

    // ── Streaming ───────────────────────────────────────────────────────────
    [ObservableProperty]
    private bool _isStreaming;

    [ObservableProperty]
    private double _currentBitrateMbps;

    [ObservableProperty]
    private int _currentFps;

    [ObservableProperty]
    private double _latencyMs;

    // ── UI ──────────────────────────────────────────────────────────────────
    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string _statusMessage = string.Empty;

    public DeviceDetailViewModel(
        IDeviceService deviceService,
        IVirtualCameraService virtualCameraService,
        ILogger<DeviceDetailViewModel> logger)
    {
        _deviceService = deviceService;
        _virtualCameraService = virtualCameraService;
        _logger = logger;
    }

    /// <summary>
    /// Populates the ViewModel from an existing <see cref="DeviceModel"/>.
    /// </summary>
    public void LoadDevice(DeviceModel device)
    {
        DeviceId = device.DeviceId;
        DeviceName = device.Name;
        Platform = device.Platform;
        Model = device.Model;
        DeviceType = device.DeviceType;
        Status = device.Status;

        if (device.Telemetry is { } t)
        {
            BatteryLevel = t.BatteryLevel;
            IsCharging = t.IsCharging;
            BatteryTemperatureC = t.BatteryTemperatureC;
            NetworkType = t.NetworkType;
        }

        if (device.CameraCapabilities is { } c)
        {
            HasFrontCamera = c.HasFront;
            HasBackCamera = c.HasBack;
            MaxResolution = c.MaxResolution;
        }
    }

    [RelayCommand]
    private async Task NavigateBackAsync()
    {
        StopTelemetryPolling();
        var mainVm = App.Services.GetService(typeof(MainViewModel)) as MainViewModel;
        if (mainVm is not null)
        {
            await mainVm.NavigateToDashboardCommand.ExecuteAsync(null);
        }
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        IsLoading = true;
        try
        {
            var device = await _deviceService.GetDeviceAsync(DeviceId);
            if (device is not null)
                LoadDevice(device);
            StatusMessage = string.Empty;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to refresh device {DeviceId}", DeviceId);
            StatusMessage = $"Refresh failed: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }    [RelayCommand]
    private async Task DisconnectDeviceAsync()
    {
        try
        {
            // Signal the backend to mark device offline via PATCH
            await _deviceService.UpdateDeviceAsync(DeviceId, new { status = "offline" });
            Status = "offline";
            IsStreaming = false;
            StatusMessage = "Device disconnected.";
            _logger.LogInformation("Device {DeviceId} disconnected.", DeviceId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to disconnect device {DeviceId}", DeviceId);
            StatusMessage = $"Disconnect failed: {ex.Message}";
        }
    }

    [RelayCommand]
    private async Task RenameDeviceAsync(string newName)
    {
        if (string.IsNullOrWhiteSpace(newName)) return;
        try
        {
            await _deviceService.UpdateDeviceAsync(DeviceId, new { name = newName });
            DeviceName = newName;
            StatusMessage = "✓ Device renamed.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to rename device {DeviceId}", DeviceId);
            StatusMessage = $"Rename failed: {ex.Message}";
        }
    }


    public void StartTelemetryPolling()
    {
        _telemetryCts = new CancellationTokenSource();
        _ = PollTelemetryAsync(_telemetryCts.Token);
    }

    public void StopTelemetryPolling()
    {
        _telemetryCts?.Cancel();
        _telemetryCts = null;
    }

    private async Task PollTelemetryAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                await RefreshAsync();
                await Task.Delay(TimeSpan.FromSeconds(5), ct);
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Telemetry poll error for {DeviceId}", DeviceId);
                await Task.Delay(TimeSpan.FromSeconds(10), ct);
            }
        }
    }
}
