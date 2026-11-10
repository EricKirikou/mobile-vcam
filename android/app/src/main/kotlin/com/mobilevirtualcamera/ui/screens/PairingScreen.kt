package com.mobilevirtualcamera.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mobilevirtualcamera.ui.theme.*

@Composable
fun PairingScreen(onBack: () -> Unit) {
    var pairingCode by remember { mutableStateOf("") }
    var pcIpAddress by remember { mutableStateOf("192.168.1.") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgDark)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 16.dp, bottom = 24.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Text("←", color = TextPrimary, fontSize = 24.sp)
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text("Pair Device", color = TextPrimary, fontSize = 20.sp)
        }

        Box(
            modifier = Modifier
                .size(240.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(SurfaceDark),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("📷", fontSize = 48.sp)
                Spacer(modifier = Modifier.height(8.dp))
                Text("Scan QR on PC", color = TextPrimary, fontSize = 14.sp)
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Text("Or Connect Directly via Local IP", color = TextSecondary, fontSize = 14.sp)

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = pcIpAddress,
            onValueChange = { pcIpAddress = it },
            label = { Text("Desktop PC IP Address") },
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = onBack,
            colors = ButtonDefaults.buttonColors(containerColor = AccentPrimary),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp)
        ) {
            Text("Connect over Local Wi-Fi")
        }
    }
}

