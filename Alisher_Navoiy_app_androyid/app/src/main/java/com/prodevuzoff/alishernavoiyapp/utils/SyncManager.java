package com.prodevuzoff.alishernavoiyapp.utils;

import android.content.ContentValues;
import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.prodevuzoff.alishernavoiyapp.database.DatabaseHelper;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.network.ApiService;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.responses.SyncManifestResponse;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SyncManager {
    private static final String TAG = "SyncManager";
    private Context context;
    private DatabaseHelper dbHelper;
    private ApiService apiService;

    public SyncManager(Context context) {
        this.context = context;
        this.dbHelper = new DatabaseHelper(context);
        this.apiService = NetworkClient.getApiService(context);
    }

    public void fetchNewAsarlar() {
        apiService.getSyncManifest().enqueue(new Callback<SyncManifestResponse>() {
            @Override
            public void onResponse(Call<SyncManifestResponse> call, Response<SyncManifestResponse> response) {
                if (response.isSuccessful() && response.body() != null) {
                    Log.d(TAG, "Manifest yuklandi");
                }
            }

            @Override
            public void onFailure(Call<SyncManifestResponse> call, Throwable t) {
                Log.e(TAG, "Manifestni yuklashda xatolik", t);
            }
        });
    }

    public void downloadAndSaveAsar(String slug) {
        apiService.downloadAsar(slug).enqueue(new Callback<Asar>() {
            @Override
            public void onResponse(Call<Asar> call, Response<Asar> response) {
                if (response.isSuccessful() && response.body() != null) {
                    saveAsarToDb(response.body());
                }
            }

            @Override
            public void onFailure(Call<Asar> call, Throwable t) {
                Log.e(TAG, "Asarni yuklab olishda xatolik: " + slug, t);
            }
        });
    }

    private void saveAsarToDb(Asar asar) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("slug", asar.slug);
        values.put("title_uz", asar.title);
        values.put("total_pages", asar.total_pages);
        values.put("is_downloaded", 1);

        db.insertWithOnConflict("asarlar", null, values, SQLiteDatabase.CONFLICT_REPLACE);
        db.close();
    }
}
