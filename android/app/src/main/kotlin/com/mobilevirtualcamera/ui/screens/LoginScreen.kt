package com.mobilevirtualcamera.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mobilevirtualcamera.ui.theme.*

@Composable
fun LoginScreen(
    onLogin: (String, String) -> Unit,
    onContinueAsGuest: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgDark)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("🎥", fontSize = 48.sp)
        Text(
            "Mobile Virtual Camera",
            color = TextPrimary,
            fontSize = 22.sp,
            modifier = Modifier.padding(top = 12.dp)
        )
        Text(
            "Local Wi-Fi pairing works without an account",
            color = LiveGreen,
            fontSize = 12.sp,
            modifier = Modifier.padding(top = 4.dp, bottom = 28.dp)
        )

        Button(
            onClick = onContinueAsGuest,
            colors = ButtonDefaults.buttonColors(containerColor = LiveGreen),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
        ) {
            Text("🚀 Continue as Guest (Local LAN)", color = BgDark, fontSize = 15.sp)
        }

        Spacer(modifier = Modifier.height(24.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Divider(modifier = Modifier.weight(1f), color = BorderDark)
            Text(
                "  OR CLOUD SIGN IN  ",
                color = TextMuted,
                fontSize = 11.sp
            )
            Divider(modifier = Modifier.weight(1f), color = BorderDark)
        }

        Spacer(modifier = Modifier.height(24.dp))

        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = { onLogin(email, password) },
            colors = ButtonDefaults.buttonColors(containerColor = AccentPrimary),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp)
        ) {
            Text("Sign In")
        }
    }
}

