package com.mobilevirtualcamera.data.models

import com.google.gson.annotations.SerializedName

// ── Authentication ────────────────────────────────────────────────────────────

data class LoginRequest(
    val email: String,
    val password: String,
    @SerializedName("deviceId") val deviceId: String,
    @SerializedName("deviceName") val deviceName: String,
    val platform: String = "android",
    @SerializedName("deviceType") val deviceType: String = "mobile"
)

data class RegisterRequest(
    val email: String,
    val password: String,
    val name: String,
    @SerializedName("deviceId") val deviceId: String,
    @SerializedName("deviceName") val deviceName: String,
    val platform: String = "android",
    @SerializedName("deviceType") val deviceType: String = "mobile"
)

data class AuthResponse(
    val success: Boolean,
    val data: AuthData?,
    val error: String?
)

data class AuthData(
    val user: UserModel,
    val tokens: AuthTokens,
    val device: DeviceModel?
)

data class UserModel(
    val id: String,
    val email: String,
    val name: String,
    val role: String = "user",
    @SerializedName("avatarUrl") val avatarUrl: String? = null
)

data class AuthTokens(
    @SerializedName("accessToken") val accessToken: String,
    @SerializedName("refreshToken") val refreshToken: String,
    @SerializedName("expiresIn") val expiresIn: String = "15m"
)

// ── Device / Pairing ──────────────────────────────────────────────────────────

data class DeviceModel(
    @SerializedName("deviceId") val deviceId: String,
    val name: String,
    val platform: String,
    @SerializedName("deviceType") val deviceType: String,
    val model: String = "",
    val status: String = "offline",
    val telemetry: DeviceTelemetry? = null,
    @SerializedName("cameraCapabilities") val cameraCapabilities: CameraCapabilities? = null
)

data class DeviceTelemetry(
    @SerializedName("batteryLevel") val batteryLevel: Int = 100,
    @SerializedName("isCharging") val isCharging: Boolean = false,
    @SerializedName("batteryTemperatureC") val batteryTemperatureC: Float = 30f,
    @SerializedName("networkType") val networkType: String = "wifi"
)

data class CameraCapabilities(
    @SerializedName("hasFront") val hasFront: Boolean = true,
    @SerializedName("hasBack") val hasBack: Boolean = true,
    @SerializedName("maxResolution") val maxResolution: String = "4K",
    @SerializedName("supportedFps") val supportedFps: List<Int> = listOf(24, 30, 60)
)

data class PairingCompleteRequest(
    @SerializedName("mobileDeviceId") val mobileDeviceId: String,
    @SerializedName("mobileDeviceName") val mobileDeviceName: String,
    @SerializedName("qrToken") val qrToken: String? = null,
    @SerializedName("pairCode") val pairCode: String? = null,
    val platform: String = "android",
    val model: String = ""
)

data class PairingResponse(
    val success: Boolean,
    val data: PairingData?,
    val error: String?
)

data class PairingData(
    @SerializedName("sharedSecret") val sharedSecret: String,
    val pairing: PairingInfo
)

data class PairingInfo(
    @SerializedName("desktopDeviceId") val desktopDeviceId: String,
    @SerializedName("mobileDeviceId") val mobileDeviceId: String,
    val alias: String,
    val status: String
)

// ── Camera RPC ────────────────────────────────────────────────────────────────

data class CameraRpcCommand(
    @SerializedName("commandId") val commandId: String,
    val action: String,
    val payload: Map<String, Any?> = emptyMap(),
    val timestamp: Long = System.currentTimeMillis()
)

data class CameraRpcResponse(
    @SerializedName("commandId") val commandId: String,
    val success: Boolean,
    val data: Map<String, Any?> = emptyMap(),
    val error: String? = null
)

// ── Video Stream Settings ─────────────────────────────────────────────────────

data class VideoProfile(
    val resolution: String = "4K",           // "720p" | "1080p" | "1440p" | "4K"
    val fps: Int = 60,
    val codec: String = "H264",              // "H264" | "H265"
    @SerializedName("bitrateKbps") val bitrateKbps: Int = 25000
)

// ── API Generic Wrapper ───────────────────────────────────────────────────────

data class ApiResponse<T>(
    val success: Boolean,
    val data: T?,
    val error: String?,
    val message: String?
)
