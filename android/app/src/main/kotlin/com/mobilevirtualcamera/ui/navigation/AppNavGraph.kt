package com.mobilevirtualcamera.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.mobilevirtualcamera.ui.screens.CameraScreen
import com.mobilevirtualcamera.ui.screens.LoginScreen
import com.mobilevirtualcamera.ui.screens.PairingScreen
import com.mobilevirtualcamera.ui.viewmodels.AuthState

sealed class Screen(val route: String) {
    object Camera : Screen("camera")
    object Pairing : Screen("pairing")
    object Login : Screen("login")
}

@Composable
fun AppNavGraph(
    navController: NavHostController,
    authState: AuthState,
    onAuthRequest: () -> Unit
) {
    val startDestination = when (authState) {
        is AuthState.Authenticated, AuthState.Guest -> Screen.Camera.route
        else -> Screen.Camera.route
    }

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Camera.route) {
            CameraScreen(
                onNavigateToPairing = { navController.navigate(Screen.Pairing.route) },
                onLogout = { navController.navigate(Screen.Login.route) }
            )
        }

        composable(Screen.Pairing.route) {
            PairingScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Login.route) {
            LoginScreen(
                onLogin = { _, _ -> navController.navigate(Screen.Camera.route) },
                onContinueAsGuest = { navController.navigate(Screen.Camera.route) }
            )
        }
    }
}

