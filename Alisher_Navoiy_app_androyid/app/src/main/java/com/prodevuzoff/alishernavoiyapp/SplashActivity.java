package com.prodevuzoff.alishernavoiyapp;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.responses.AppConfigResponse;
import com.scottyab.rootbeer.RootBeer;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SplashActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        applyTheme();
        super.onCreate(savedInstanceState);
        
        try {
            setContentView(R.layout.activity_splash);
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (checkLocalSecurity()) {
            checkAppConfigFromServer();
        }
    }

    private boolean checkLocalSecurity() {
        RootBeer rootBeer = new RootBeer(this);
        if (rootBeer.isRooted()) {
            showExitDialog("Xavfsizlik", "Qurilmangizda Root ruxsati aniqlandi. Ilova xavfsizlik sababli ishlamaydi.");
            return false;
        }
        return true;
    }

    private void checkAppConfigFromServer() {
        NetworkClient.getApiService(this).getAppConfig().enqueue(new Callback<AppConfigResponse>() {
            @Override
            public void onResponse(@NonNull Call<AppConfigResponse> call, @NonNull Response<AppConfigResponse> response) {
                if (response.isSuccessful() && response.body() != null) {
                    handleAppConfig(response.body());
                } else {
                    // Serverdan javob kelmasa ham davom etaveramiz (offline rejim uchun)
                    proceedToNext();
                }
            }

            @Override
            public void onFailure(@NonNull Call<AppConfigResponse> call, @NonNull Throwable t) {
                // Tarmoq xatosi bo'lsa ham davom etamiz
                proceedToNext();
            }
        });
    }

    private void handleAppConfig(AppConfigResponse config) {
        if (config.maintenanceMode) {
            showExitDialog("Texnik ishlar", "Hozirda ilovada texnik ishlar ketmoqda. Iltimos, birozdan so'ng urinib ko'ring.");
            return;
        }

        int currentVersion = BuildConfig.VERSION_CODE;
        if (currentVersion < config.minVersion) {
            showUpdateDialog(config.updateUrl, true);
        } else if (currentVersion < config.latestVersion) {
            showUpdateDialog(config.updateUrl, false);
        } else {
            proceedToNext();
        }
    }

    private void showUpdateDialog(String updateUrl, boolean isForce) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle("Yangilanish")
                .setMessage(isForce ? "Ilovaning yangi talqini chiqdi. Davom etish uchun yangilashingiz shart." 
                                   : "Ilovaning yangi talqini mavjud. Yangilashni xohlaysizmi?")
                .setCancelable(!isForce)
                .setPositiveButton("Yangilash", (dialog, which) -> {
                    Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(updateUrl));
                    startActivity(intent);
                    if (isForce) finish();
                });

        if (!isForce) {
            builder.setNegativeButton("Keyinroq", (dialog, which) -> proceedToNext());
        }

        builder.show();
    }

    private void showExitDialog(String title, String message) {
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage(message)
                .setCancelable(false)
                .setPositiveButton("Chiqish", (dialog, which) -> finish())
                .show();
    }

    private void proceedToNext() {
        new Handler(Looper.getMainLooper()).postDelayed(this::checkUserSession, 1000);
    }

    private void checkUserSession() {
        SharedPreferences prefs = getSharedPreferences("Settings", Context.MODE_PRIVATE);
        boolean isLoggedIn = prefs.getBoolean("is_logged_in", false);

        Intent intent;
        if (isLoggedIn) {
            intent = new Intent(SplashActivity.this, MainActivity.class);
        } else {
            intent = new Intent(SplashActivity.this, LoginActivity.class);
        }
        startActivity(intent);
        finish();
    }

    private void applyTheme() {
        SharedPreferences prefs = getSharedPreferences("Settings", Context.MODE_PRIVATE);
        String theme = prefs.getString("app_theme", "classic");
        
        switch (theme) {
            case "modern":
                setTheme(R.style.Theme_AlisherNavoiyApp_Modern);
                break;
            case "dark":
                setTheme(R.style.Theme_AlisherNavoiyApp_Dark);
                break;
            default:
                setTheme(R.style.Theme_AlisherNavoiyApp_Classic);
                break;
        }
    }
}
