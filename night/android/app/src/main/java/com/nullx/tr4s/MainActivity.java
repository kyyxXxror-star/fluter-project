package com.nullx.tr4s;

import androidx.annotation.NonNull;

import android.util.Base64;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import okhttp3.OkHttpClient;
import okhttp3.Request;

import org.json.JSONObject;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "remote_gate";

    // URL GitHub sudah di-encode
    private static final String RGS_RAVEN =
            "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1h5enpNb29kcy9zZXR0aW5ncy9tYWluL3NlYy5qc29u";

    private String decodeUrl() {
        byte[] decoded = Base64.decode(RGS_RAVEN, Base64.DEFAULT);
        return new String(decoded);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        ).setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("check")) {
                        new Thread(() -> {
                            try {
                                OkHttpClient client = new OkHttpClient();

                                String url = decodeUrl(); // decode di runtime

                                Request request = new Request.Builder()
                                        .url(url)
                                        .build();

                                String body = client
                                        .newCall(request)
                                        .execute()
                                        .body()
                                        .string();

                                JSONObject json = new JSONObject(body);
                                boolean error = json.optBoolean("error", true);

                                // error=false => allow
                                result.success(!error);

                            } catch (Exception e) {
                                result.success(false); // gagal = block
                            }
                        }).start();
                    } else {
                        result.notImplemented();
                    }
                }
        );
    }
}