using System;

namespace MobileVirtualCamera.Desktop;

/// <summary>
/// Compile-time and runtime application configuration constants.
/// Values are overridden from appsettings.json or environment variables at runtime.
/// </summary>
public static class AppSettings
{
    /// <summary>Base URL of the Mobile Virtual Camera backend REST API.</summary>
    public static string BackendBaseUrl { get; set; } =
        Environment.GetEnvironmentVariable("MVC_BACKEND_URL") ?? "http://localhost:5000";

    /// <summary>WebSocket/Socket.IO URL for the signaling server.</summary>
    public static string SignalingUrl { get; set; } =
        Environment.GetEnvironmentVariable("MVC_SIGNALING_URL") ?? "http://localhost:5000";

    /// <summary>Unique stable identifier for this desktop installation.</summary>
    public static string DesktopDeviceId { get; set; } = GetOrCreateDeviceId();

    /// <summary>Human-readable device name shown in the UI and paired phone list.</summary>
    public static string DesktopDeviceName { get; set; } =
        Environment.MachineName ?? "My Windows PC";

    /// <summary>Application version string for the auto-updater.</summary>
    public const string AppVersion = "1.0.0";

    /// <summary>Minimum target streaming latency in milliseconds.</summary>
    public const int TargetLatencyMs = 150;

    /// <summary>Heartbeat interval for keep-alive socket pings (ms).</summary>
    public const int HeartbeatIntervalMs = 15_000;

    private static string GetOrCreateDeviceId()
    {
        const string regKey = @"SOFTWARE\MobileVirtualCamera";
        const string regValue = "DeviceId";
        try
        {
            using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(regKey, writable: true)
                            ?? Microsoft.Win32.Registry.CurrentUser.CreateSubKey(regKey);
            var existing = key?.GetValue(regValue) as string;
            if (!string.IsNullOrWhiteSpace(existing)) return existing;

            var newId = $"win-{Guid.NewGuid():N}";
            key?.SetValue(regValue, newId);
            return newId;
        }
        catch
        {
            return $"win-{Guid.NewGuid():N}"; // Fallback: not persisted across restarts in edge case
        }
    }
}
