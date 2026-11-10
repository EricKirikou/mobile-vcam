package com.mobilevirtualcamera

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber

@HiltAndroidApp
class MvcApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Initialize structured logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }
        Timber.i("Mobile Virtual Camera Application started")
    }
}
