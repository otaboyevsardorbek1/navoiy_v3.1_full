package com.prodevuzoff.alishernavoiyapp.fragments;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.responses.SyncManifestResponse;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SyncFragment extends Fragment {

    private TextView textViewLastSync, textViewStorageInfo, textViewProgressLabel;
    private Button buttonSyncNow;
    private ProgressBar progressBarSync;
    private SharedPreferences prefs;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_sync, container, false);
        
        textViewLastSync = view.findViewById(R.id.textViewLastSync);
        textViewStorageInfo = view.findViewById(R.id.textViewStorageInfo);
        textViewProgressLabel = view.findViewById(R.id.textViewProgressLabel);
        buttonSyncNow = view.findViewById(R.id.buttonSyncNow);
        progressBarSync = view.findViewById(R.id.progressBarSync);

        prefs = requireContext().getSharedPreferences("SyncPrefs", Context.MODE_PRIVATE);
        
        updateUI();

        buttonSyncNow.setOnClickListener(v -> startSync());

        return view;
    }

    private void updateUI() {
        long lastSync = prefs.getLong("last_sync_time", 0);
        if (lastSync == 0) {
            textViewLastSync.setText("Oxirgi sinxronizatsiya: Hech qachon");
        } else {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault());
            textViewLastSync.setText("Oxirgi sinxronizatsiya: " + sdf.format(new Date(lastSync)));
        }

        File dir = new File(requireContext().getFilesDir(), "asarlar");
        int count = 0;
        if (dir.exists() && dir.isDirectory()) {
            File[] files = dir.listFiles();
            if (files != null) count = files.length;
        }
        textViewStorageInfo.setText("Offline asarlar soni: " + count);
    }

    private void startSync() {
        buttonSyncNow.setEnabled(false);
        progressBarSync.setVisibility(View.VISIBLE);
        textViewProgressLabel.setVisibility(View.VISIBLE);
        textViewProgressLabel.setText("Manifest yuklanmoqda...");

        NetworkClient.getApiService(requireContext()).getSyncManifest().enqueue(new Callback<SyncManifestResponse>() {
            @Override
            public void onResponse(Call<SyncManifestResponse> call, Response<SyncManifestResponse> response) {
                if (response.isSuccessful() && response.body() != null) {
                    downloadAsarlar(response.body().asarlar);
                } else {
                    handleError("Manifest yuklashda xato");
                }
            }

            @Override
            public void onFailure(Call<SyncManifestResponse> call, Throwable t) {
                handleError("Server bilan aloqa yo'q");
            }
        });
    }

    private void downloadAsarlar(List<SyncManifestResponse.SyncItemMeta> asarlar) {
        if (asarlar == null || asarlar.isEmpty()) {
            finishSync();
            return;
        }

        final int total = asarlar.size();
        final int[] completed = {0};

        for (SyncManifestResponse.SyncItemMeta item : asarlar) {
            NetworkClient.getApiService(requireContext()).downloadAsar(item.slug).enqueue(new Callback<Asar>() {
                @Override
                public void onResponse(Call<Asar> call, Response<Asar> response) {
                    if (response.isSuccessful() && response.body() != null) {
                        saveAsarLocally(item.slug, response.body());
                    }
                    completed[0]++;
                    updateProgress(completed[0], total);
                    if (completed[0] == total) {
                        finishSync();
                    }
                }

                @Override
                public void onFailure(Call<Asar> call, Throwable t) {
                    completed[0]++;
                    if (completed[0] == total) {
                        finishSync();
                    }
                }
            });
        }
    }

    private void saveAsarLocally(String slug, Asar asar) {
        try {
            File dir = new File(requireContext().getFilesDir(), "asarlar");
            if (!dir.exists()) dir.mkdirs();
            File file = new File(dir, slug + ".json");
            FileOutputStream fos = new FileOutputStream(file);
            String json = new com.google.gson.Gson().toJson(asar);
            fos.write(json.getBytes(StandardCharsets.UTF_8));
            fos.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void updateProgress(int current, int total) {
        int percent = (int) ((current / (float) total) * 100);
        progressBarSync.setProgress(percent);
        textViewProgressLabel.setText("Yuklanmoqda: " + current + "/" + total);
    }

    private void finishSync() {
        prefs.edit().putLong("last_sync_time", System.currentTimeMillis()).apply();
        buttonSyncNow.setEnabled(true);
        progressBarSync.setVisibility(View.GONE);
        textViewProgressLabel.setText("Sinxronizatsiya yakunlandi");
        updateUI();
        Toast.makeText(getContext(), "Barcha ma'lumotlar yangilandi", Toast.LENGTH_SHORT).show();
    }

    private void handleError(String message) {
        buttonSyncNow.setEnabled(true);
        progressBarSync.setVisibility(View.GONE);
        textViewProgressLabel.setText(message);
        Toast.makeText(getContext(), message, Toast.LENGTH_SHORT).show();
    }
}