using MobileVirtualCamera.Desktop.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MobileVirtualCamera.Desktop.Services;

public class DeviceService : IDeviceService
{
    private readonly IApiService _apiService;

    public DeviceService(IApiService apiService) => _apiService = apiService;

    public async Task<IEnumerable<DeviceModel>> GetPairedDevicesAsync()
    {
        var response = await _apiService.GetAsync<ApiResponse<IEnumerable<DeviceModel>>>("/api/devices");
        return response?.Data ?? [];
    }

    public async Task<DeviceModel?> GetDeviceAsync(string deviceId)
    {
        var response = await _apiService.GetAsync<ApiResponse<DeviceModel>>($"/api/devices/{deviceId}");
        return response?.Data;
    }

    public async Task UpdateDeviceAsync(string deviceId, object updateData)
    {
        await _apiService.PatchAsync<object>($"/api/devices/{deviceId}", updateData);
    }
}

public interface IDeviceService
{
    Task<IEnumerable<DeviceModel>> GetPairedDevicesAsync();
    Task<DeviceModel?> GetDeviceAsync(string deviceId);
    Task UpdateDeviceAsync(string deviceId, object updateData);
}
