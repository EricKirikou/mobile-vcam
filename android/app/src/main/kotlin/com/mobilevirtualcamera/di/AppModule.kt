package com.mobilevirtualcamera.di

import android.content.Context
import com.mobilevirtualcamera.data.local.TokenStore
import com.mobilevirtualcamera.data.network.ApiService
import com.mobilevirtualcamera.data.network.AuthInterceptor
import com.mobilevirtualcamera.data.network.NetworkModule
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideTokenStore(@ApplicationContext context: Context): TokenStore = TokenStore(context)

    @Provides
    @Singleton
    fun provideAuthInterceptor(tokenStore: TokenStore): AuthInterceptor = AuthInterceptor(tokenStore)

    @Provides
    @Singleton
    fun provideNetworkModule(authInterceptor: AuthInterceptor): NetworkModule = NetworkModule(authInterceptor)

    @Provides
    @Singleton
    fun provideApiService(networkModule: NetworkModule): ApiService = networkModule.apiService
}

