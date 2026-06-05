package com.prodevuzoff.alishernavoiyapp.fragments;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RadioGroup;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.prodevuzoff.alishernavoiyapp.AdminActivity;
import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.database.SessionManager;

public class SettingsFragment extends Fragment {

    private EditText editTextApiUrl;
    private Button buttonSaveSettings, btnAdminPanel;
    private RadioGroup radioGroupTheme;
    private SwitchMaterial switchOfflineMode;
    private SharedPreferences prefs;
    private SessionManager sessionManager;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_settings, container, false);
        
        editTextApiUrl = view.findViewById(R.id.editTextApiUrl);
        buttonSaveSettings = view.findViewById(R.id.buttonSaveSettings);
        btnAdminPanel = view.findViewById(R.id.btnAdminPanel);
        radioGroupTheme = view.findViewById(R.id.radioGroupTheme);
        switchOfflineMode = view.findViewById(R.id.switchOfflineMode);
        
        prefs = requireContext().getSharedPreferences("Settings", Context.MODE_PRIVATE);
        sessionManager = new SessionManager(requireContext());
        
        // Load current settings
        String currentUrl = prefs.getString("api_url", "http://10.0.2.2:8000/api/v1/");
        editTextApiUrl.setText(currentUrl);
        
        boolean isOffline = prefs.getBoolean("offline_mode", false);
        switchOfflineMode.setChecked(isOffline);
        
        String theme = prefs.getString("app_theme", "classic");
        if ("modern".equals(theme)) radioGroupTheme.check(R.id.radioModern);
        else if ("dark".equals(theme)) radioGroupTheme.check(R.id.radioDark);
        else radioGroupTheme.check(R.id.radioClassic);

        buttonSaveSettings.setOnClickListener(v -> saveSettings());

        // Admin panel tugmasi faqat adminlar uchun ko'rinadi
        if ("admin".equalsIgnoreCase(sessionManager.getUserRole())) {
            btnAdminPanel.setVisibility(View.VISIBLE);
            btnAdminPanel.setOnClickListener(v -> {
                startActivity(new Intent(getActivity(), AdminActivity.class));
            });
        } else {
            btnAdminPanel.setVisibility(View.GONE);
        }

        return view;
    }

    private void saveSettings() {
        String newUrl = editTextApiUrl.getText().toString().trim();
        
        if (TextUtils.isEmpty(newUrl)) {
            editTextApiUrl.setError("URL bo'sh bo'lishi mumkin emas");
            return;
        }

        if (!newUrl.startsWith("http://") && !newUrl.startsWith("https://")) {
            editTextApiUrl.setError("URL 'http://' yoki 'https://' bilan boshlanishi kerak");
            return;
        }

        SharedPreferences.Editor editor = prefs.edit();
        editor.putString("api_url", newUrl);
        editor.putBoolean("offline_mode", switchOfflineMode.isChecked());
        
        String oldTheme = prefs.getString("app_theme", "classic");
        String newTheme;

        int checkedId = radioGroupTheme.getCheckedRadioButtonId();
        if (checkedId == R.id.radioModern) newTheme = "modern";
        else if (checkedId == R.id.radioDark) newTheme = "dark";
        else newTheme = "classic";
        
        editor.putString("app_theme", newTheme);
        editor.apply();

        Toast.makeText(getContext(), "Sozlamalar saqlandi", Toast.LENGTH_SHORT).show();

        if (!oldTheme.equals(newTheme)) {
            updateThemeDynamic();
        }
    }

    private void updateThemeDynamic() {
        if (getActivity() != null) {
            getActivity().recreate();
        }
    }
}
