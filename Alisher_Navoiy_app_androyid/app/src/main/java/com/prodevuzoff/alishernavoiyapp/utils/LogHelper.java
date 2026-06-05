package com.prodevuzoff.alishernavoiyapp.utils;

import android.content.Context;
import android.util.Log;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import java.util.HashMap;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LogHelper {

    public static void logAuth(Context context, String action, String username, String details) {
        Map<String, String> logData = new HashMap<>();
        logData.put("action", action);
        logData.put("username", username);
        logData.put("details", details);
        logData.put("device", android.os.Build.MODEL);

        NetworkClient.getApiService(context).sendAuthLog(logData).enqueue(new Callback<Object>() {
            @Override
            public void onResponse(Call<Object> call, Response<Object> response) {
                if (response.isSuccessful()) {
                    Log.d("LogHelper", "Log sent successfully");
                }
            }

            @Override
            public void onFailure(Call<Object> call, Throwable t) {
                Log.e("LogHelper", "Failed to send log", t);
            }
        });
    }

    public static void syncLogs(Context context) {
        // Implementation for offline logs sync if needed
    }
}