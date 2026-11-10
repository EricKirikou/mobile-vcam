package com.mobilevirtualcamera.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mobilevirtualcamera.data.local.TokenStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class AuthState {
    object Initial : AuthState()
    object Loading : AuthState()
    data class Authenticated(val userName: String, val email: String) : AuthState()
    object Guest : AuthState()
    data class Error(val message: String) : AuthState()
}

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val tokenStore: TokenStore
) : ViewModel() {

    private val _authState = MutableStateFlow<AuthState>(AuthState.Initial)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    init {
        initialize()
    }

    fun initialize() {
        viewModelScope.launch {
            if (tokenStore.isLoggedIn()) {
                val name = tokenStore.getUserName() ?: "User"
                val email = tokenStore.getUserEmail() ?: ""
                _authState.value = AuthState.Authenticated(name, email)
            } else {
                // Default to Guest mode directly so user is never locked out!
                _authState.value = AuthState.Guest
            }
        }
    }

    fun continueAsGuest() {
        _authState.value = AuthState.Guest
    }

    fun login(email: String, pass: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            if (email.isNotBlank() && pass.isNotBlank()) {
                tokenStore.saveTokens("mock_jwt_access", "mock_jwt_refresh")
                tokenStore.saveUserInfo("user_1", email.substringBefore("@"), email)
                _authState.value = AuthState.Authenticated(email.substringBefore("@"), email)
            } else {
                _authState.value = AuthState.Error("Please enter email and password")
            }
        }
    }

    fun logout() {
        tokenStore.clearAll()
        _authState.value = AuthState.Guest
    }
}

