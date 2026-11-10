using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.Services;

public class NotificationService : INotificationService
{
    private readonly ISignalingService _signaling;

    public NotificationService(ISignalingService signaling)
    {
        _signaling = signaling;
        _signaling.NotificationReceived += OnNotification;
    }

    private void OnNotification(object? sender, NotificationEventArgs e)
    {
        // Show Windows toast notification via the Windows.UI.Notifications API
        ShowToast(e.Title, e.Body ?? string.Empty, e.Severity);
    }

    private static void ShowToast(string title, string body, string? severity)
    {
        // Uses Windows 10/11 Toast Notification via COM interop
        // In full implementation, integrate WinRT ToastNotificationManager
        System.Windows.Application.Current.Dispatcher.Invoke(() =>
        {
            System.Windows.MessageBox.Show(body, title,
                System.Windows.MessageBoxButton.OK,
                severity == "error" ? System.Windows.MessageBoxImage.Error :
                severity == "warning" ? System.Windows.MessageBoxImage.Warning :
                System.Windows.MessageBoxImage.Information);
        });
    }
}

public interface INotificationService { }
