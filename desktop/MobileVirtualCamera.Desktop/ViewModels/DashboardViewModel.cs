using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MobileVirtualCamera.Desktop.Models;
using MobileVirtualCamera.Desktop.Services;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.ViewModels;

/// <summary>
/// Dashboard ViewModel: manages connected device list, streaming state,
/// real-time metrics, and virtual camera lifecycle.
/// </summary>
public partial class DashboardViewModel : ObservableObject
{
    private readonly IDeviceService _deviceService;
    private readonly ISignalingService _signalingService;
    private readonly IVirtualCameraService _virtualCameraService;
    private readonly IApiService _apiService;
    private readonly ILogger<DashboardViewModel> _logger;
    private CancellationTokenSource? _metricsCts;

    [ObservableProperty]
    private ObservableCollection<DeviceViewModel> _pairedDevices = [];

    [ObservableProperty]
    private DeviceViewModel? _selectedDevice;

    [ObservableProperty]
    private bool _isStreaming;

    [ObservableProperty]
    private bool _isVirtualCameraActive;

    [ObservableProperty]
    private string _connectionStatus = "Idle";

    [ObservableProperty]
    private double _currentLatencyMs;

    [ObservableProperty]
    private double _currentFps;

    [ObservableProperty]
    private double _currentBitrateKbps;

    [ObservableProperty]
    private double _signalQualityPct = 100;

    [ObservableProperty]
    private string _currentResolution = "4K (3840x2160)";

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string _statusMessage = string.Empty;

    [ObservableProperty]
    private ObservableCollection<MetricDataPoint> _latencyHistory = [];

    [ObservableProperty]
    private ObservableCollection<MetricDataPoint> _bitrateHistory = [];

    public DashboardViewModel(
        IDeviceService deviceService,
        ISignalingService signalingService,
        IVirtualCameraService virtualCameraService,
        IApiService apiService,
        ILogger<DashboardViewModel> logger)
    {
        _deviceService = deviceService;
        _signalingService = signalingService;
        _virtualCameraService = virtualCameraService;
        _apiService = apiService;
        _logger = logger;

        // Subscribe to real-time events from signaling service
        _signalingService.DeviceStatusChanged += OnDeviceStatusChanged;
        _signalingService.MetricsReceived += OnMetricsReceived;
        _signalingService.StreamingStateChanged += OnStreamingStateChanged;
    }

    public async Task LoadAsync()
    {
        IsLoading = true;
        try
        {
            var devices = await _deviceService.GetPairedDevicesAsync();
            PairedDevices.Clear();
            foreach (var d in devices)
                PairedDevices.Add(new DeviceViewModel(d));

            ConnectionStatus = "Ready";
            StatusMessage = $"{PairedDevices.Count} device(s) paired";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load dashboard");
            StatusMessage = $"Error: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand(CanExecute = nameof(CanStartStream))]
    private async Task StartStreamAsync()
    {
        if (SelectedDevice is null) return;

        IsLoading = true;
        StatusMessage = "Initiating connection...";
        ConnectionStatus = "Connecting";

        try
        {
            // Activate virtual camera driver before streaming begins
            await _virtualCameraService.StartVirtualCameraAsync();
            IsVirtualCameraActive = true;

            // Send signaling request to mobile device
            var sessionId = await _signalingService.RequestSessionAsync(
                SelectedDevice.DeviceId,
                new VideoProfile
                {
                    Resolution = CurrentResolution,
                    Fps = 60,
                    Codec = "H264",
                    BitrateKbps = 25000
                });

            if (sessionId is not null)
            {
                IsStreaming = true;
                ConnectionStatus = "Connected";
                StatusMessage = $"Streaming from {SelectedDevice.Name}";
                _logger.LogInformation("Stream started: session={SessionId}", sessionId);
                StartMetricsPolling();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to start stream");
            StatusMessage = $"Connection failed: {ex.Message}";
            ConnectionStatus = "Failed";
            await _virtualCameraService.StopVirtualCameraAsync();
            IsVirtualCameraActive = false;
        }
        finally
        {
            IsLoading = false;
        }
    }

    private bool CanStartStream() =>
        SelectedDevice is not null && !IsStreaming && SelectedDevice.IsOnline;

    [RelayCommand(CanExecute = nameof(CanStopStream))]
    private async Task StopStreamAsync()
    {
        try
        {
            StopMetricsPolling();
            await _signalingService.EndSessionAsync();
            await _virtualCameraService.StopVirtualCameraAsync();
            IsStreaming = false;
            IsVirtualCameraActive = false;
            ConnectionStatus = "Disconnected";
            StatusMessage = "Stream stopped";
            CurrentLatencyMs = 0;
            CurrentFps = 0;
            CurrentBitrateKbps = 0;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error stopping stream");
        }
    }

    private bool CanStopStream() => IsStreaming;

    [RelayCommand]
    private async Task TakeSnapshotAsync()
    {
        if (SelectedDevice is null) return;
        try
        {
            await _apiService.PostAsync<object>(
                $"/api/devices/{SelectedDevice.DeviceId}/camera/photo",
                new { highRes = true });
            StatusMessage = "Snapshot captured!";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Snapshot failed: {ex.Message}";
        }
    }

    [RelayCommand]
    private async Task SwitchCameraAsync()
    {
        if (SelectedDevice is null) return;
        await _apiService.PostAsync<object>(
            $"/api/devices/{SelectedDevice.DeviceId}/camera/switch",
            new { facing = "toggle" });
    }

    [RelayCommand]
    private async Task ToggleFlashAsync()
    {
        if (SelectedDevice is null) return;
        await _apiService.PostAsync<object>(
            $"/api/devices/{SelectedDevice.DeviceId}/camera/controls",
            new { flash = !SelectedDevice.IsFlashOn });
    }

    private void StartMetricsPolling()
    {
        _metricsCts = new CancellationTokenSource();
    }

    private void StopMetricsPolling()
    {
        _metricsCts?.Cancel();
        _metricsCts = null;
    }

    private void OnDeviceStatusChanged(object? sender, DeviceStatusEventArgs e)
    {
        var device = PairedDevices.FirstOrDefault(d => d.DeviceId == e.DeviceId);
        if (device is not null)
        {
            device.IsOnline = e.IsOnline;
            device.BatteryLevel = e.BatteryLevel ?? 0;
        }
        else if (e.IsOnline)
        {
            _ = LoadAsync(); // Refresh if a new device came online
        }
    }

    private void OnMetricsReceived(object? sender, MetricsEventArgs e)
    {
        CurrentLatencyMs = e.LatencyMs;
        CurrentFps = e.Fps;
        CurrentBitrateKbps = e.BitrateKbps;
        SignalQualityPct = CalculateSignalQuality(e.PacketLossPct, e.LatencyMs);

        // Rolling history for bandwidth graph (keep last 60 points)
        LatencyHistory.Add(new MetricDataPoint(DateTime.Now, e.LatencyMs));
        BitrateHistory.Add(new MetricDataPoint(DateTime.Now, e.BitrateKbps));
        if (LatencyHistory.Count > 60) LatencyHistory.RemoveAt(0);
        if (BitrateHistory.Count > 60) BitrateHistory.RemoveAt(0);

        // Update selected device battery
        if (SelectedDevice is not null && e.BatteryLevel.HasValue)
            SelectedDevice.BatteryLevel = (int)e.BatteryLevel.Value;
    }

    private void OnStreamingStateChanged(object? sender, StreamingStateEventArgs e)
    {
        IsStreaming = e.IsStreaming;
        if (!e.IsStreaming)
        {
            ConnectionStatus = "Disconnected";
            StatusMessage = e.Reason ?? "Stream ended";
        }
    }

    [RelayCommand]
    private void ViewDeviceDetail(DeviceViewModel? device)
    {
        if (device is null) return;
        var detailVm = App.Services.GetService(typeof(DeviceDetailViewModel)) as DeviceDetailViewModel;
        if (detailVm is not null)
        {
            detailVm.LoadDevice(new DeviceModel
            {
                DeviceId = device.DeviceId,
                Name = device.Name,
                Platform = device.Platform,
                DeviceType = device.DeviceType,
                Status = device.Status,
                Telemetry = new DeviceTelemetry
                {
                    BatteryLevel = device.BatteryLevel,
                    NetworkType = "Wi-Fi"
                }
            });
            var mainVm = App.Services.GetService(typeof(MainViewModel)) as MainViewModel;
            if (mainVm is not null) mainVm.CurrentPage = detailVm;
        }
    }

    private static double CalculateSignalQuality(double packetLoss, double latencyMs)
    {
        double latencyScore = latencyMs < 50 ? 100 : latencyMs < 150 ? 80 : latencyMs < 300 ? 50 : 20;
        double lossScore = packetLoss < 1 ? 100 : packetLoss < 5 ? 70 : packetLoss < 10 ? 40 : 10;
        return (latencyScore + lossScore) / 2.0;
    }
}

/// <summary>Thin device wrapper for DataGrid / ListView binding.</summary>
public partial class DeviceViewModel : ObservableObject
{
    public string DeviceId { get; }
    public string Name { get; }
    public string Platform { get; }
    public string DeviceType { get; }

    [ObservableProperty] private bool _isOnline;
    [ObservableProperty] private int _batteryLevel;
    [ObservableProperty] private string _status = "Offline";
    [ObservableProperty] private bool _isFlashOn;
    [ObservableProperty] private double _latencyMs;

    public DeviceViewModel(DeviceModel model)
    {
        DeviceId = model.DeviceId;
        Name = model.Name;
        Platform = model.Platform;
        DeviceType = model.DeviceType;
        IsOnline = model.Status == "online";
        BatteryLevel = model.Telemetry?.BatteryLevel ?? 100;
        Status = model.Status;
    }
}

public record MetricDataPoint(DateTime Timestamp, double Value);
