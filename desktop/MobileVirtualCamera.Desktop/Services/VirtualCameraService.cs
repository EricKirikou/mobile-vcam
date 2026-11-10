using Microsoft.Extensions.Logging;
using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.Services;

/// <summary>
/// Manages the Windows Virtual Camera (MediaFoundation Virtual Camera API, Windows 11+)
/// with DirectShow virtual camera as fallback for Windows 10.
///
/// The virtual camera registers itself as a system camera device,
/// making it visible in Zoom, Teams, OBS, Discord, Chrome, etc.
///
/// NOTE: Full implementation requires the native C++ COM virtual camera driver DLL
/// (VirtualCameraDriver.dll) bundled alongside this application.
/// This service wraps P/Invoke calls into that driver.
/// </summary>
public class VirtualCameraService : IVirtualCameraService
{
    private readonly ILogger<VirtualCameraService> _logger;
    private bool _isRunning;
    private IntPtr _cameraHandle = IntPtr.Zero;
    private bool _usingDirectShowFallback;

    // ── P/Invoke into our native virtual camera driver DLL ────────────────────
    [DllImport("VirtualCameraDriver.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern int VCam_Initialize();

    [DllImport("VirtualCameraDriver.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr VCam_Start(int width, int height, int fps);

    [DllImport("VirtualCameraDriver.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern int VCam_PushFrame(IntPtr handle, IntPtr rgbBuffer, int bufferSize);

    [DllImport("VirtualCameraDriver.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern int VCam_Stop(IntPtr handle);

    [DllImport("VirtualCameraDriver.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern void VCam_Uninitialize();

    public bool IsRunning => _isRunning;
    public bool IsUsingFallback => _usingDirectShowFallback;

    public VirtualCameraService(ILogger<VirtualCameraService> logger)
    {
        _logger = logger;
    }

    public async Task StartVirtualCameraAsync(int width = 3840, int height = 2160, int fps = 60)
    {
        if (_isRunning)
        {
            _logger.LogWarning("Virtual camera already running. Ignoring duplicate start.");
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                _logger.LogInformation("Initializing Windows Virtual Camera API (MediaFoundation)...");
                var initResult = VCam_Initialize();

                if (initResult != 0)
                {
                    _logger.LogWarning("MediaFoundation VCam init failed (code {Code}). Falling back to DirectShow.", initResult);
                    StartDirectShowFallback(width, height, fps);
                    return;
                }

                _cameraHandle = VCam_Start(width, height, fps);
                if (_cameraHandle == IntPtr.Zero)
                {
                    throw new Exception("VCam_Start returned a null handle");
                }

                _isRunning = true;
                _usingDirectShowFallback = false;
                _logger.LogInformation("Virtual camera started: {W}x{H} @ {FPS} fps", width, height, fps);
            }
            catch (DllNotFoundException)
            {
                _logger.LogWarning("VirtualCameraDriver.dll not found. Using DirectShow fallback.");
                StartDirectShowFallback(width, height, fps);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start virtual camera");
                throw;
            }
        });
    }

    private void StartDirectShowFallback(int width, int height, int fps)
    {
        // DirectShow virtual camera is implemented via a separate filter DLL
        // registered with regsvr32 during installation.
        // This sets the resolution parameters via registry values read by the filter.
        try
        {
            using var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(
                @"SOFTWARE\MobileVirtualCamera\DirectShow");
            key.SetValue("Width", width);
            key.SetValue("Height", height);
            key.SetValue("FPS", fps);
            key.SetValue("Active", 1);

            _isRunning = true;
            _usingDirectShowFallback = true;
            _logger.LogInformation("DirectShow fallback camera configured: {W}x{H} @ {FPS} fps", width, height, fps);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DirectShow fallback configuration failed");
            throw;
        }
    }

    /// <summary>
    /// Pushes a decoded video frame (RGB32 raw bytes) into the virtual camera buffer.
    /// Called from the WebRTC decode pipeline on a background thread.
    /// </summary>
    public unsafe void PushFrame(byte[] rgbBuffer, int width, int height)
    {
        if (!_isRunning || _cameraHandle == IntPtr.Zero || _usingDirectShowFallback) return;

        fixed (byte* ptr = rgbBuffer)
        {
            VCam_PushFrame(_cameraHandle, (IntPtr)ptr, rgbBuffer.Length);
        }
    }

    public async Task StopVirtualCameraAsync()
    {
        if (!_isRunning) return;

        await Task.Run(() =>
        {
            try
            {
                if (_cameraHandle != IntPtr.Zero)
                {
                    VCam_Stop(_cameraHandle);
                    VCam_Uninitialize();
                    _cameraHandle = IntPtr.Zero;
                }

                if (_usingDirectShowFallback)
                {
                    using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(
                        @"SOFTWARE\MobileVirtualCamera\DirectShow", writable: true);
                    key?.SetValue("Active", 0);
                }

                _isRunning = false;
                _logger.LogInformation("Virtual camera stopped");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error stopping virtual camera");
            }
        });
    }
}

public interface IVirtualCameraService
{
    bool IsRunning { get; }
    bool IsUsingFallback { get; }
    Task StartVirtualCameraAsync(int width = 3840, int height = 2160, int fps = 60);
    void PushFrame(byte[] rgbBuffer, int width, int height);
    Task StopVirtualCameraAsync();
}
