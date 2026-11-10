using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.IO;

namespace MobileVirtualCamera.Desktop.Services;

public class FileTransferService : IFileTransferService
{
    private readonly IApiService _apiService;
    private readonly HttpClient _httpClient;

    public FileTransferService(IApiService apiService, HttpClient httpClient)
    {
        _apiService = apiService;
        _httpClient = httpClient;
    }

    public async Task<string?> SendFileAsync(string targetDeviceId, string localFilePath)
    {
        await using var stream = File.OpenRead(localFilePath);
        var content = new MultipartFormDataContent();
        var fileContent = new StreamContent(stream);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("application/octet-stream");
        content.Add(fileContent, "file", Path.GetFileName(localFilePath));
        content.Add(new StringContent(targetDeviceId), "targetDeviceId");

        var response = await _httpClient.PostAsync("/api/files/upload", content);
        response.EnsureSuccessStatusCode();
        return response.RequestMessage?.RequestUri?.ToString();
    }

    public async Task DownloadFileAsync(string downloadUrl, string savePath)
    {
        var bytes = await _httpClient.GetByteArrayAsync(downloadUrl);
        await File.WriteAllBytesAsync(savePath, bytes);
    }
}

public interface IFileTransferService
{
    Task<string?> SendFileAsync(string targetDeviceId, string localFilePath);
    Task DownloadFileAsync(string downloadUrl, string savePath);
}
