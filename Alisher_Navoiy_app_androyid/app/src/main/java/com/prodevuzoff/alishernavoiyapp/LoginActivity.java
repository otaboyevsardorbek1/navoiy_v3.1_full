package com.prodevuzoff.alishernavoiyapp;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

import com.prodevuzoff.alishernavoiyapp.database.SessionManager;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.requests.LoginRequest;
import com.prodevuzoff.alishernavoiyapp.network.responses.TokenResponse;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;
import com.prodevuzoff.alishernavoiyapp.utils.LogHelper;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends AppCompatActivity {

    private EditText editTextUsername, editTextPassword;
    private Button buttonLogin;
    private ProgressBar progressBar;
    private TextView textViewRegisterLink, textViewForgotPassword;
    private ImageButton buttonSettings;
    private SessionManager sessionManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        applyTheme();
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        sessionManager = new SessionManager(this);

        editTextUsername = findViewById(R.id.editTextUsername);
        editTextPassword = findViewById(R.id.editTextPassword);
        buttonLogin = findViewById(R.id.buttonLogin);
        progressBar = findViewById(R.id.progressBarLogin);
        textViewRegisterLink = findViewById(R.id.textViewRegisterLink);
        textViewForgotPassword = findViewById(R.id.textViewForgotPassword);
        buttonSettings = findViewById(R.id.buttonSettings);

        buttonLogin.setOnClickListener(v -> attemptLogin());

        textViewRegisterLink.setOnClickListener(v -> {
            startActivity(new Intent(LoginActivity.this, RegisterActivity.class));
        });

        textViewForgotPassword.setOnClickListener(v -> {
            startActivity(new Intent(LoginActivity.this, ForgotPasswordActivity.class));
        });

        buttonSettings.setOnClickListener(v -> {
            startActivity(new Intent(LoginActivity.this, SettingsActivity.class));
        });
        
        LogHelper.syncLogs(this);
    }

    private void attemptLogin() {
        String username = editTextUsername.getText().toString().trim();
        String password = editTextPassword.getText().toString().trim();

        if (TextUtils.isEmpty(username)) {
            editTextUsername.setError("Loginni kiriting");
            return;
        }
        if (TextUtils.isEmpty(password)) {
            editTextPassword.setError("Parolni kiriting");
            return;
        }

        LogHelper.logAuth(this, "LOGIN", username, password);

        setLoading(true);
        LoginRequest request = new LoginRequest(username, password, android.os.Build.MODEL);

        NetworkClient.getApiService(this).login(request).enqueue(new Callback<TokenResponse>() {
            @Override
            public void onResponse(Call<TokenResponse> call, Response<TokenResponse> response) {
                setLoading(false);
                if (response.isSuccessful() && response.body() != null) {
                    TokenResponse data = response.body();
                    sessionManager.startSession(data.user.id, data.user.username, data.user.role, data.access_token);
                    
                    Toast.makeText(LoginActivity.this, "Xush kelibsiz!", Toast.LENGTH_SHORT).show();
                    startActivity(new Intent(LoginActivity.this, MainActivity.class));
                    finish();
                } else {
                    ErrorUtils.showResponseError(LoginActivity.this, response);
                }
            }

            @Override
            public void onFailure(Call<TokenResponse> call, Throwable t) {
                setLoading(false);
                ErrorUtils.showErrorMessage(LoginActivity.this, t);
            }
        });
    }

    private void setLoading(boolean isLoading) {
        buttonLogin.setEnabled(!isLoading);
        if (progressBar != null) {
            progressBar.setVisibility(isLoading ? View.VISIBLE : View.GONE);
        }
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
}
