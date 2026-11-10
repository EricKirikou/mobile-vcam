package com.mobilevirtualcamera.data.network

import com.mobilevirtualcamera.data.models.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    // ── Authentication ────────────────────────────────────────────────────────
    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @POST("api/auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST("api/auth/google")
    suspend fun googleAuth(@Body body: Map<String, String>): Response<AuthResponse>

    @POST("api/auth/refresh")
    suspend fun refreshToken(@Body body: Map<String, String>): Response<ApiResponse<AuthTokens>>

    @POST("api/auth/logout")
    suspend fun logout(): Response<ApiResponse<Unit>>

    @GET("api/auth/profile")
    suspend fun getProfile(): Response<ApiResponse<Any>>

    // ── Device Management ─────────────────────────────────────────────────────
    @GET("api/devices")
    suspend fun getDevices(): Response<ApiResponse<List<DeviceModel>>>

    @PATCH("api/devices/{deviceId}")
    suspend fun updateDevice(
        @Path("deviceId") deviceId: String,
        @Body updates: Map<String, Any>
    ): Response<ApiResponse<DeviceModel>>

    // ── Pairing ───────────────────────────────────────────────────────────────
    @POST("api/pairings/complete")
    suspend fun completePairing(@Body request: PairingCompleteRequest): Response<PairingResponse>

    @GET("api/pairings")
    suspend fun getPairings(): Response<ApiResponse<List<Any>>>

    @PATCH("api/pairings/{id}")
    suspend fun updatePairing(
        @Path("id") pairingId: String,
        @Body body: Map<String, Any>
    ): Response<ApiResponse<Any>>

    // ── ICE Servers / TURN ────────────────────────────────────────────────────
    @GET("api/ice-servers")
    suspend fun getIceServers(): Response<ApiResponse<IceConfig>>

    // ── Settings ──────────────────────────────────────────────────────────────
    @GET("api/settings")
    suspend fun getSettings(): Response<ApiResponse<Any>>

    @PATCH("api/settings")
    suspend fun updateSettings(@Body settings: Map<String, Any>): Response<ApiResponse<Any>>

    // ── Analytics ─────────────────────────────────────────────────────────────
    @GET("api/analytics/summary")
    suspend fun getAnalyticsSummary(): Response<ApiResponse<Any>>
}

data class IceConfig(
    val iceServers: List<IceServer>,
    val iceTransportPolicy: String = "all",
    val ttl: Int = 86400
)

data class IceServer(
    val urls: List<String>,
    val username: String? = null,
    val credential: String? = null
)
