using Microsoft.Extensions.Logging;
using MobileVirtualCamera.Desktop.Models;
using SocketIOClient;
using System;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.Services;

/// <summary>
/// Manages the Socket.IO connection to the backend signaling server.
/// Handles WebRTC SDP offer/answer relay, ICE candidate exchange,
/// real-time metrics, device presence events, and clipboard sync signals.
/// </summary>
public class SignalingService : ISignalingService, IAsyncDisposable
{
    private readonly IAuthService _authService;
    private readonly ILogger<SignalingService> _logger;
    private SocketIOClient.SocketIO? _socket;
    private string? _currentSessionId;
    private bool _isConnected;

    // ── Events consumed by ViewModels ─────────────────────────────────────────
    public event EventHandler<DeviceStatusEventArgs>? DeviceStatusChanged;
    public event EventHandler<MetricsEventArgs>? MetricsReceived;
    public event EventHandler<StreamingStateEventArgs>? StreamingStateChanged;
    public event EventHandler<SdpEventArgs>? SdpAnswerReceived;
    public event EventHandler<IceCandidateEventArgs>? IceCandidateReceived;
    public event EventHandler<ClipboardSyncEventArgs>? ClipboardSyncReceived;
    public event EventHandler<NotificationEventArgs>? NotificationReceived;

    public bool IsConnected => _isConnected;
    public string? CurrentSessionId => _currentSessionId;

    public SignalingService(IAuthService authService, ILogger<SignalingService> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    public async Task ConnectAsync()
    {
        var token = _authService.GetAccessToken();
        if (string.IsNullOrEmpty(token)) throw new InvalidOperationException("Cannot connect: not authenticated.");

        _socket = new SocketIOClient.SocketIO(AppSettings.SignalingUrl, new SocketIOOptions
        {
            Auth = new { token, deviceId = AppSettings.DesktopDeviceId },
            Reconnection = true,
            ReconnectionAttempts = int.MaxValue,
            ReconnectionDelay = 1000,
            ReconnectionDelayMax = 10000,
            Transport = SocketIOClient.Transport.TransportProtocol.WebSocket
        });

        RegisterSocketEvents();

        await _socket.ConnectAsync();
        _logger.LogInformation("SignalingService connected to {Url}", AppSettings.SignalingUrl);
    }

    private void RegisterSocketEvents()
    {
        if (_socket is null) return;

        _socket.OnConnected += (s, e) =>
        {
            _isConnected = true;
            _logger.LogInformation("Socket.IO connected");
        };

        _socket.OnDisconnected += (s, e) =>
        {
            _isConnected = false;
            _logger.LogWarning("Socket.IO disconnected: {Reason}", e);
            StreamingStateChanged?.Invoke(this, new StreamingStateEventArgs(false, "Connection lost — reconnecting..."));
        };

        // ── WebRTC Signaling Events ───────────────────────────────────────────
        _socket.On("signaling:answer", response =>
        {
            var data = response.GetValue<SdpData>();
            _logger.LogDebug("SDP Answer received for session {SessionId}", data.SessionId);
            SdpAnswerReceived?.Invoke(this, new SdpEventArgs(data.SessionId, data.Sdp));
        });

        _socket.On("signaling:ice_candidate", response =>
        {
            var data = response.GetValue<IceCandidateData>();
            IceCandidateReceived?.Invoke(this, new IceCandidateEventArgs(
                data.SessionId, data.Candidate, data.SdpMid, data.SdpMLineIndex));
        });

        _socket.On("signaling:stream_live", response =>
        {
            var data = response.GetValue<SessionData>();
            _logger.LogInformation("Stream is LIVE: session={SessionId}", data.SessionId);
            StreamingStateChanged?.Invoke(this, new StreamingStateEventArgs(true, null));
        });

        _socket.On("signaling:session_ended", response =>
        {
            var data = response.GetValue<SessionData>();
            _logger.LogInformation("Session ended: session={SessionId}", data.SessionId);
            _currentSessionId = null;
            StreamingStateChanged?.Invoke(this, new StreamingStateEventArgs(false, "Session ended by remote"));
        });

        // ── Device Presence Events ────────────────────────────────────────────
        _socket.On("device:online", response =>
        {
            var data = response.GetValue<DevicePresenceData>();
            DeviceStatusChanged?.Invoke(this, new DeviceStatusEventArgs(data.DeviceId, true));
        });

        _socket.On("device:offline", response =>
        {
            var data = response.GetValue<DevicePresenceData>();
            DeviceStatusChanged?.Invoke(this, new DeviceStatusEventArgs(data.DeviceId, false));
        });

        // ── Live Metrics ──────────────────────────────────────────────────────
        _socket.On("metrics:live", response =>
        {
            var data = response.GetValue<MetricsData>();
            MetricsReceived?.Invoke(this, new MetricsEventArgs(
                data.LatencyMs, data.Fps, data.BitrateKbps, data.PacketLossPct, data.BatteryLevel));
        });

        // ── Clipboard Sync ────────────────────────────────────────────────────
        _socket.On("clipboard:sync", response =>
        {
            var data = response.GetValue<ClipboardData>();
            ClipboardSyncReceived?.Invoke(this, new ClipboardSyncEventArgs(data.Text, data.MimeType));
        });

        // ── Notifications ─────────────────────────────────────────────────────
        _socket.On("notification", response =>
        {
            var data = response.GetValue<NotificationData>();
            NotificationReceived?.Invoke(this, new NotificationEventArgs(data.Type, data.Title, data.Body, data.Severity));
        });

        // ── Heartbeat ─────────────────────────────────────────────────────────
        _ = Task.Run(async () =>
        {
            while (true)
            {
                await Task.Delay(AppSettings.HeartbeatIntervalMs);
                if (_isConnected && _socket is not null)
                {
                    await _socket.EmitAsync("heartbeat");
                }
            }
        });
    }

    public async Task<string?> RequestSessionAsync(string targetDeviceId, VideoProfile profile)
    {
        if (!_isConnected || _socket is null)
            throw new InvalidOperationException("Not connected to signaling server.");

        string? sessionId = null;
        await _socket.EmitAsync("signaling:request_session", response =>
        {
            var data = response.GetValue<SessionResponseData>();
            sessionId = data?.SessionId;
        }, new { targetDeviceId, videoProfile = profile });

        _currentSessionId = sessionId;
        return sessionId;
    }

    public async Task SendSdpOfferAsync(string sessionId, string sdp)
    {
        if (_socket is null) return;
        await _socket.EmitAsync("signaling:offer", new { sessionId, sdp });
    }

    public async Task SendIceCandidateAsync(string sessionId, string candidate, string sdpMid, int sdpMLineIndex)
    {
        if (_socket is null) return;
        await _socket.EmitAsync("signaling:ice_candidate", new { sessionId, candidate, sdpMid, sdpMLineIndex });
    }

    public async Task EndSessionAsync()
    {
        if (_socket is null || _currentSessionId is null) return;
        await _socket.EmitAsync("signaling:end_session", new { sessionId = _currentSessionId });
        _currentSessionId = null;
    }

    public async Task SyncClipboardAsync(string targetDeviceId, string text)
    {
        if (_socket is null) return;
        await _socket.EmitAsync("clipboard:push", new { targetDeviceId, text, mimeType = "text/plain" });
    }

    public async ValueTask DisposeAsync()
    {
        if (_socket is not null)
        {
            await _socket.DisconnectAsync();
            _socket.Dispose();
        }
    }
}

public interface ISignalingService
{
    bool IsConnected { get; }
    event EventHandler<DeviceStatusEventArgs>? DeviceStatusChanged;
    event EventHandler<MetricsEventArgs>? MetricsReceived;
    event EventHandler<StreamingStateEventArgs>? StreamingStateChanged;
    event EventHandler<SdpEventArgs>? SdpAnswerReceived;
    event EventHandler<IceCandidateEventArgs>? IceCandidateReceived;
    event EventHandler<ClipboardSyncEventArgs>? ClipboardSyncReceived;
    event EventHandler<NotificationEventArgs>? NotificationReceived;
    Task ConnectAsync();
    Task<string?> RequestSessionAsync(string targetDeviceId, VideoProfile profile);
    Task SendSdpOfferAsync(string sessionId, string sdp);
    Task SendIceCandidateAsync(string sessionId, string candidate, string sdpMid, int sdpMLineIndex);
    Task EndSessionAsync();
    Task SyncClipboardAsync(string targetDeviceId, string text);
}

// ── Event Args ─────────────────────────────────────────────────────────────────
public record DeviceStatusEventArgs(string DeviceId, bool IsOnline, int? BatteryLevel = null);
public record MetricsEventArgs(double LatencyMs, double Fps, double BitrateKbps, double PacketLossPct, double? BatteryLevel);
public record StreamingStateEventArgs(bool IsStreaming, string? Reason);
public record SdpEventArgs(string SessionId, string Sdp);
public record IceCandidateEventArgs(string SessionId, string Candidate, string? SdpMid, int SdpMLineIndex);
public record ClipboardSyncEventArgs(string? Text, string? MimeType);
public record NotificationEventArgs(string Type, string Title, string? Body, string? Severity);

// ── Socket.IO data models ──────────────────────────────────────────────────────
internal record SdpData(string SessionId, string Sdp, string FromDeviceId);
internal record IceCandidateData(string SessionId, string Candidate, string? SdpMid, int SdpMLineIndex);
internal record SessionData(string SessionId, string? InitiatorDeviceId);
internal record SessionResponseData(string? SessionId, string? Error);
internal record DevicePresenceData(string DeviceId, long Timestamp);
internal record MetricsData(double LatencyMs, double Fps, double BitrateKbps, double PacketLossPct, double? BatteryLevel);
internal record ClipboardData(string? Text, string? MimeType, string SenderDeviceId);
internal record NotificationData(string Type, string Title, string? Body, string? Severity);
