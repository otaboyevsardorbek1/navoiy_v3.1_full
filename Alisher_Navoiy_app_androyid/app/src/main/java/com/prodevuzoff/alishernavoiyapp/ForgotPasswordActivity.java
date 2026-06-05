package com.prodevuzoff.alishernavoiyapp;

import android.os.Bundle;
import android.text.TextUtils;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.prodevuzoff.alishernavoiyapp.network.ApiService;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.requests.ForgotPasswordRequest;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ForgotPasswordActivity extends AppCompatActivity {

    private EditText editTextEmail;
    private Button buttonReset;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_forgot_password);

        Toolbar toolbar = findViewById(R.id.toolbarForgot);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Parolni tiklash");
        }

        editTextEmail = findViewById(R.id.editTextEmail);
        buttonReset = findViewById(R.id.buttonReset);

        buttonReset.setOnClickListener(v -> {
            String email = editTextEmail.getText().toString().trim();
            if (TextUtils.isEmpty(email)) {
                editTextEmail.setError("Emailni kiriting");
                return;
            }

            ApiService apiService = NetworkClient.getApiService(this);
            apiService.resetPassword(new ForgotPasswordRequest(email)).enqueue(new Callback<Object>() {
                @Override
                public void onResponse(Call<Object> call, Response<Object> response) {
                    if (response.isSuccessful()) {
                        Toast.makeText(ForgotPasswordActivity.this, "Tiklash kodi emailingizga yuborildi", Toast.LENGTH_LONG).show();
                        finish();
                    } else {
                        ErrorUtils.showResponseError(ForgotPasswordActivity.this, response);
                    }
                }

                @Override
                public void onFailure(Call<Object> call, Throwable t) {
                    ErrorUtils.showErrorMessage(ForgotPasswordActivity.this, t);
                }
            });
        });
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }
}
