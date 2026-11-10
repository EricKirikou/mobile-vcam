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
fun CameraScreen(
    onNavigateToPairing: () -> Unit,
    onLogout: () -> Unit
) {
    var isStreaming by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgDark)
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Mobile Virtual Camera",
                    color = TextPrimary,
                    fontSize = 20.sp,
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = if (isStreaming) "● 4K 60fps Live Streaming" else "○ Ready to stream",
                    color = if (isStreaming) LiveGreen else TextSecondary,
                    fontSize = 12.sp
                )
            }

            IconButton(onClick = onNavigateToPairing) {
                Text("📱", fontSize = 24.sp)
            }
        }

        // Camera Preview Area Placeholder
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(vertical = 24.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(SurfaceDark),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "📷",
                    fontSize = 48.sp,
                    modifier = Modifier.padding(bottom = 12.dp)
                )
                Text(
                    text = if (isStreaming) "Camera feed active" else "Virtual Camera Ready",
                    color = TextPrimary,
                    fontSize = 16.sp
                )
                Text(
                    text = "Resolution: 4K UHD (3840×2160) @ 60fps",
                    color = LiveGreen,
                    fontSize = 12.sp,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }

        // Streaming Controls
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Button(
                onClick = { isStreaming = !isStreaming },
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isStreaming) DangerRed else AccentPrimary
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
            ) {
                Text(
                    text = if (isStreaming) "Stop Streaming" else "Start 4K Streaming",
                    fontSize = 16.sp
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedButton(
                onClick = onNavigateToPairing,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
            ) {
                Text("Pair with PC / QR Code", color = TextSecondary)
            }
        }
    }
}

