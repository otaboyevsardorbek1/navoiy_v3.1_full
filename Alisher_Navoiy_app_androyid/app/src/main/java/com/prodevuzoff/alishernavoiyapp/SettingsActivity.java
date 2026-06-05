package com.prodevuzoff.alishernavoiyapp;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;

import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SettingsActivity extends AppCompatActivity {

    private RadioGroup radioGroupThemes;
    private RadioButton radioClassic, radioModern, radioDark;
    private Button buttonApplyTheme;
    private EditText editTextApiUrl;
    
    // Admin settings
    private LinearLayout layoutAdminSettings;
    private EditText editTextBotToken, editTextChatId;
    
    // Admin Panel access
    private int logoClickCount = 0;
    private long lastClickTime = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        applyTheme();
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        Toolbar toolbar = findViewById(R.id.toolbarSettings);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        radioGroupThemes = findViewById(R.id.radioGroupThemes);
        radioClassic = findViewById(R.id.radioClassic);
        radioModern = findViewById(R.id.radioModern);
        radioDark = findViewById(R.id.radioDark);
        buttonApplyTheme = findViewById(R.id.buttonApplyTheme);
        editTextApiUrl = findViewById(R.id.editTextApiUrl);
        
        layoutAdminSettings = findViewById(R.id.layoutAdminSettings);
        editTextBotToken = findViewById(R.id.editTextBotToken);
        editTextChatId = findViewById(R.id.editTextChatId);

        TextView tvVersion = findViewById(R.id.textViewVersion);
        if (tvVersion != null) {
            tvVersion.setOnClickListener(v -> handleAdminSecretClick());
        }

        checkAdminAccess();
        loadCurrentSettings();

        buttonApplyTheme.setOnClickListener(v -> saveSettings());
    }

    private void handleAdminSecretClick() {
        long currentTime = System.currentTimeMillis();
        if (currentTime - lastClickTime < 500) {
            logoClickCount++;
        } else {
            logoClickCount = 1;
        }
        lastClickTime = currentTime;

        if (logoClickCount == 5) {
            logoClickCount = 0;
            startActivity(new Intent(this, AdminActivity.class));
        } else if (logoClickCount > 2) {
            Toast.makeText(this, "Admin panelga kirish uchun yana " + (5 - logoClickCount) + " marta bosing", Toast.LENGTH_SHORT).show();
        }
    }

    private void checkAdminAccess() {
        SharedPreferences authPrefs = getSharedPreferences("Auth", MODE_PRIVATE);
        String role = authPrefs.getString("role", "user");
        
        if ("admin".equalsIgnoreCase(role)) {
            layoutAdminSettings.setVisibility(View.VISIBLE);
            fetchSettingsFromBackend();
        } else {
            layoutAdminSettings.setVisibility(View.GONE);
        }
    }

    private void fetchSettingsFromBackend() {
        NetworkClient.getApiService(this).getAdminSettings().enqueue(new Callback<Map<String, String>>() {
            @Override
            public void onResponse(Call<Map<String, String>> call, Response<Map<String, String>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    Map<String, String> settings = response.body();
                    if (settings.containsKey("bot_token")) editTextBotToken.setText(settings.get("bot_token"));
                    if (settings.containsKey("chat_id")) editTextChatId.setText(settings.get("chat_id"));
                }
            }
            @Override
            public void onFailure(Call<Map<String, String>> call, Throwable t) {}
        });
    }

    private void loadCurrentSettings() {
        SharedPreferences prefs = getSharedPreferences("Settings", Context.MODE_PRIVATE);
        String apiUrl = prefs.getString("api_url", "http://10.0.2.2:8000/api/v1/");
        editTextApiUrl.setText(apiUrl);

        String theme = prefs.getString("app_theme", "classic");
        switch (theme) {
            case "modern": radioModern.setChecked(true); break;
            case "dark": radioDark.setChecked(true); break;
            default: radioClassic.setChecked(true); break;
        }
    }

    private void saveSettings() {
        String newUrl = editTextApiUrl.getText().toString().trim();
        if (TextUtils.isEmpty(newUrl)) {
            Toast.makeText(this, "API URL bo'sh bo'lishi mumkin emas", Toast.LENGTH_SHORT).show();
            return;
        }

        String selectedTheme = "classic";
        int checkedId = radioGroupThemes.getCheckedRadioButtonId();
        if (checkedId == R.id.radioModern) selectedTheme = "modern";
        else if (checkedId == R.id.radioDark) selectedTheme = "dark";

        getSharedPreferences("Settings", MODE_PRIVATE).edit()
            .putString("api_url", newUrl)
            .putString("app_theme", selectedTheme).apply();

        if (layoutAdminSettings.getVisibility() == View.VISIBLE) {
            updateBackendSetting("bot_token", editTextBotToken.getText().toString().trim());
            updateBackendSetting("chat_id", editTextChatId.getText().toString().trim());
        }

        Toast.makeText(this, "Sozlamalar saqlandi", Toast.LENGTH_SHORT).show();
        restartApp();
    }

    private void updateBackendSetting(String key, String value) {
        NetworkClient.getApiService(this).updateAdminSetting(key, value).enqueue(new Callback<Object>() {
            @Override
            public void onResponse(Call<Object> call, Response<Object> response) {}
            @Override
            public void onFailure(Call<Object> call, Throwable t) {}
        });
    }

    private void restartApp() {
        Intent intent = new Intent(this, SplashActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
    }

    private void applyTheme() {
        SharedPreferences prefs = getSharedPreferences("Settings", Context.MODE_PRIVATE);
        String theme = prefs.getString("app_theme", "classic");
        switch (theme) {
            case "modern": setTheme(R.style.Theme_AlisherNavoiyApp_Modern); break;
            case "dark": setTheme(R.style.Theme_AlisherNavoiyApp_Dark); break;
            default: setTheme(R.style.Theme_AlisherNavoiyApp_Classic); break;
        }
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }
}
