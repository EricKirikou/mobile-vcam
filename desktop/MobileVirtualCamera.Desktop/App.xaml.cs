using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MobileVirtualCamera.Desktop.Services;
using MobileVirtualCamera.Desktop.ViewModels;
using Serilog;
using System;
using System.IO;
using System.Windows;

namespace MobileVirtualCamera.Desktop;

/// <summary>
/// Application entry point. Configures the DI container, logging,
/// and launches the main WPF window.
/// </summary>
public partial class App : Application
{
    public static IServiceProvider Services { get; private set; } = null!;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // ── Configure Serilog ─────────────────────────────────────────────────
        var logPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "MobileVirtualCamera", "logs", "app-.log");

        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Debug()
            .WriteTo.Console()
            .WriteTo.File(logPath, rollingInterval: RollingInterval.Day, retainedFileCountLimit: 7)
            .CreateLogger();

        Log.Information("Mobile Virtual Camera Desktop starting up...");

        // ── Configure DI Container ────────────────────────────────────────────
        var services = new ServiceCollection();
        ConfigureServices(services);
        Services = services.BuildServiceProvider();

        // ── Launch Main Window ────────────────────────────────────────────────
        var mainWindow = Services.GetRequiredService<MainWindow>();
        mainWindow.Show();
    }

    private static void ConfigureServices(IServiceCollection services)
    {
        // Logging
        services.AddLogging(builder =>
        {
            builder.ClearProviders();
            builder.AddSerilog(dispose: true);
        });

        // HttpClient for backend API
        services.AddHttpClient<IApiService, ApiService>(client =>
        {
            client.BaseAddress = new Uri(AppSettings.BackendBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(30);
            client.DefaultRequestHeaders.Add("Accept", "application/json");
        });

        // Core services
        services.AddSingleton<IAuthService, AuthService>();
        services.AddSingleton<ISignalingService, SignalingService>();
        services.AddSingleton<IVirtualCameraService, VirtualCameraService>();
        services.AddSingleton<IDeviceService, DeviceService>();
        services.AddSingleton<IPairingService, PairingService>();
        services.AddSingleton<INotificationService, NotificationService>();
        services.AddSingleton<ISettingsService, SettingsService>();
        services.AddSingleton<IClipboardSyncService, ClipboardSyncService>();
        services.AddSingleton<IFileTransferService, FileTransferService>();
        services.AddSingleton<IUpdateService, UpdateService>();

        // ViewModels
        services.AddSingleton<MainViewModel>();
        services.AddSingleton<DashboardViewModel>();
        services.AddSingleton<LoginViewModel>();
        services.AddSingleton<PairingViewModel>();
        services.AddSingleton<SettingsViewModel>();
        services.AddSingleton<DeviceDetailViewModel>();

        // Views
        services.AddTransient<MainWindow>();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        Log.Information("Mobile Virtual Camera Desktop shutting down.");
        Log.CloseAndFlush();
        base.OnExit(e);
    }

    private void Application_DispatcherUnhandledException(object sender,
        System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
    {
        Log.Fatal(e.Exception, "Unhandled UI exception");
        MessageBox.Show(
            $"An unexpected error occurred:\n{e.Exception.Message}\n\nPlease check the logs.",
            "Mobile Virtual Camera – Error",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
        e.Handled = true;
    }
}
