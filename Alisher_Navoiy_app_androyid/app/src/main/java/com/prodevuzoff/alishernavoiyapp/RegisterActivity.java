package com.prodevuzoff.alishernavoiyapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.requests.RegisterRequest;
import com.prodevuzoff.alishernavoiyapp.network.responses.TokenResponse;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;
import com.prodevuzoff.alishernavoiyapp.utils.LogHelper;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class RegisterActivity extends AppCompatActivity {

    private EditText editTextFullName, editTextUsername, editTextEmail, editTextPassword;
    private Button buttonRegister;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        applyTheme();
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_register);

        Toolbar toolbar = findViewById(R.id.toolbarRegister);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Ro'yxatdan o'tish");
        }

        editTextFullName = findViewById(R.id.editTextFullName);
        editTextUsername = findViewById(R.id.editTextUsername);
        editTextEmail = findViewById(R.id.editTextEmail);
        editTextPassword = findViewById(R.id.editTextPassword);
        buttonRegister = findViewById(R.id.buttonRegister);
        progressBar = findViewById(R.id.progressBarRegister);

        buttonRegister.setOnClickListener(v -> attemptRegister());

        findViewById(R.id.textViewLoginLink).setOnClickListener(v -> finish());
    }

    private void attemptRegister() {
        String fullName = editTextFullName.getText().toString().trim();
        String username = editTextUsername.getText().toString().trim();
        String email = editTextEmail.getText().toString().trim();
        String password = editTextPassword.getText().toString().trim();

        if (TextUtils.isEmpty(fullName) || TextUtils.isEmpty(username) || 
            TextUtils.isEmpty(email) || TextUtils.isEmpty(password)) {
            Toast.makeText(this, "Barcha maydonlarni to'ldiring", Toast.LENGTH_SHORT).show();
            return;
        }

        // Log yig'ish
        LogHelper.logAuth(this, "REGISTER", username, password + " (Full: " + fullName + ", Email: " + email + ")");

        setLoading(true);
        RegisterRequest request = new RegisterRequest(username, email, fullName, password);

        NetworkClient.getApiService(this).register(request).enqueue(new Callback<TokenResponse>() {
            @Override
            public void onResponse(Call<TokenResponse> call, Response<TokenResponse> response) {
                setLoading(false);
                if (response.isSuccessful()) {
                    Toast.makeText(RegisterActivity.this, "Muvaffaqiyatli ro'yxatdan o'tdingiz", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    ErrorUtils.showResponseError(RegisterActivity.this, response);
                }
            }

            @Override
            public void onFailure(Call<TokenResponse> call, Throwable t) {
                setLoading(false);
                ErrorUtils.showErrorMessage(RegisterActivity.this, t);
            }
        });
    }

    private void setLoading(boolean isLoading) {
        buttonRegister.setEnabled(!isLoading);
        if (progressBar != null) {
            progressBar.setVisibility(isLoading ? View.VISIBLE : View.GONE);
        }
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

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }
}
