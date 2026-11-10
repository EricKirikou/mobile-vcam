using MobileVirtualCamera.Desktop.Models;
using System;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.Services;

public class PairingService : IPairingService
{
    private readonly IApiService _apiService;
    public PairingService(IApiService apiService) => _apiService = apiService;

    public async Task<PairingResult> CreatePairingAsync(string desktopDeviceId)
    {
        var response = await _apiService.PostAsync<ApiResponse<PairingResult>>(
            "/api/pairings", new { desktopDeviceId });
        return response?.Data ?? throw new Exception("Failed to create pairing session");
    }

    public async Task<PairingStatusResult?> CheckPairingStatusAsync(string qrToken)
    {
        // Poll the backend to see if the mobile has scanned and confirmed
        var pairings = await _apiService.GetAsync<ApiResponse<System.Collections.Generic.List<PairingStatusResult>>>("/api/pairings");
        return pairings?.Data?.Find(p => p.QrToken == qrToken);
    }
}

public interface IPairingService
{
    Task<PairingResult> CreatePairingAsync(string desktopDeviceId);
    Task<PairingStatusResult?> CheckPairingStatusAsync(string qrToken);
}
