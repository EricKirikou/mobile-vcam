using System.Threading.Tasks;
using System.Windows;

namespace MobileVirtualCamera.Desktop.Services;

/// <summary>
/// Listens for clipboard:sync events from the signaling layer
/// and writes the received text to the Windows clipboard.
/// Also provides push-to-phone capability.
/// </summary>
public class ClipboardSyncService : IClipboardSyncService
{
    private readonly ISignalingService _signaling;

    public ClipboardSyncService(ISignalingService signaling)
    {
        _signaling = signaling;
        _signaling.ClipboardSyncReceived += OnClipboardReceived;
    }

    private void OnClipboardReceived(object? sender, ClipboardSyncEventArgs e)
    {
        if (string.IsNullOrEmpty(e.Text)) return;
        // Must run on the UI/STA thread
        Application.Current.Dispatcher.Invoke(() =>
        {
            Clipboard.SetText(e.Text);
        });
    }

    public async Task PushToPhoneAsync(string targetDeviceId, string text)
    {
        await _signaling.SyncClipboardAsync(targetDeviceId, text);
    }
}

public interface IClipboardSyncService
{
    Task PushToPhoneAsync(string targetDeviceId, string text);
}
