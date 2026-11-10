using System;
using System.Collections.Generic;

namespace MobileVirtualCamera.Desktop.Models;

public record UserModel
{
    public string Id { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Role { get; init; } = "user";
    public string? AvatarUrl { get; init; }
}

public record AuthTokens
{
    public string AccessToken { get; init; } = string.Empty;
    public string RefreshToken { get; init; } = string.Empty;
    public string ExpiresIn { get; init; } = "15m";
}

public record LoginRequest
{
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string? DeviceId { get; init; }
    public string? DeviceName { get; init; }
    public string? Platform { get; init; }
    public string? DeviceType { get; init; }
}

public record LoginResult
{
    public UserModel User { get; init; } = new();
    public AuthTokens Tokens { get; init; } = new();
    public DeviceModel? Device { get; init; }
}

public record ProfileResult
{
    public UserModel User { get; init; } = new();
    public object? Settings { get; init; }
}

public record DeviceModel
{
    public string DeviceId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Platform { get; init; } = string.Empty;
    public string DeviceType { get; init; } = string.Empty;
    public string Model { get; init; } = string.Empty;
    public string Status { get; init; } = "offline";
    public DeviceTelemetry? Telemetry { get; init; }
    public CameraCapabilities? CameraCapabilities { get; init; }
    public DateTime LastSeenAt { get; init; }
}

public record DeviceTelemetry
{
    public int BatteryLevel { get; init; } = 100;
    public bool IsCharging { get; init; }
    public double BatteryTemperatureC { get; init; }
    public string NetworkType { get; init; } = "wifi";
}

public record CameraCapabilities
{
    public bool HasFront { get; init; } = true;
    public bool HasBack { get; init; } = true;
    public string MaxResolution { get; init; } = "1080p";
    public List<int> SupportedFps { get; init; } = [24, 30, 60];
}

public record PairingResult
{
    public string PairingId { get; init; } = string.Empty;
    public string PairCode { get; init; } = string.Empty;
    public string QrToken { get; init; } = string.Empty;
    public string QrCodeDataUrl { get; init; } = string.Empty;
    public DateTime ExpiresAt { get; init; }
}

public record PairingStatusResult
{
    public string Status { get; init; } = string.Empty;
    public string? QrToken { get; init; }
    public string? MobileDeviceName { get; init; }
}

public record VideoProfile
{
    public string Resolution { get; init; } = "1080p";
    public int Fps { get; init; } = 30;
    public string Codec { get; init; } = "H264";
    public int BitrateKbps { get; init; } = 4500;
}

public record ApiResponse<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Error { get; init; }
    public string? Message { get; init; }
}

public record DiscoveredDevice
{
    public string Name { get; init; } = string.Empty;
    public string IpAddress { get; init; } = string.Empty;
    public string Platform { get; init; } = string.Empty;
    public int Port { get; init; } = 8765;
}

public enum AppTheme { Light, Dark, System }
