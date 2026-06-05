package com.prodevuzoff.alishernavoiyapp.network;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.google.gson.Gson;
import com.prodevuzoff.alishernavoiyapp.database.DatabaseHelper;
import com.prodevuzoff.alishernavoiyapp.models.Asar;

import java.util.HashMap;
import java.util.Map;

import retrofit2.Response;

public class SyncWorker extends Worker {
    private final DatabaseHelper dbHelper;
    private final Gson gson;

    public SyncWorker(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
        dbHelper = new DatabaseHelper(context);
        gson = new Gson();
    }

    @NonNull
    @Override
    public Result doWork() {
        Log.d("SyncWorker", "Sinxronizatsiya boshlandi...");
        syncSessionLogs();
        syncPendingUploads();
        return Result.success();
    }

    private void syncSessionLogs() {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = db.query("session_activity_logs", null, "is_synced = 0", null, null, null, null);

        while (cursor.moveToNext()) {
            int id = cursor.getInt(cursor.getColumnIndexOrThrow("id"));
            Map<String, Object> logData = new HashMap<>();
            logData.put("type", cursor.getString(cursor.getColumnIndexOrThrow("action_type")));
            logData.put("details", cursor.getString(cursor.getColumnIndexOrThrow("details")));
            logData.put("timestamp", cursor.getString(cursor.getColumnIndexOrThrow("timestamp")));

            try {
                Response<Object> response = NetworkClient.getApiService(getApplicationContext())
                        .sendActivityLog(logData).execute();
                if (response.isSuccessful()) {
                    dbHelper.getWritableDatabase().execSQL("UPDATE session_activity_logs SET is_synced = 1 WHERE id = " + id);
                }
            } catch (Exception e) {
                Log.e("SyncWorker", "Log sync error: " + e.getMessage());
            }
        }
        cursor.close();
    }

    private void syncPendingUploads() {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = db.query("pending_uploads", null, "is_synced = 0", null, null, null, null);

        while (cursor.moveToNext()) {
            int id = cursor.getInt(cursor.getColumnIndexOrThrow("id"));
            String type = cursor.getString(cursor.getColumnIndexOrThrow("upload_type"));
            String json = cursor.getString(cursor.getColumnIndexOrThrow("data_json"));

            if ("asar".equals(type)) {
                Asar asar = gson.fromJson(json, Asar.class);
                try {
                    Response<Map<String, Object>> response = NetworkClient.getApiService(getApplicationContext())
                            .uploadAsarContent(asar.slug, asar).execute();
                    if (response.isSuccessful()) {
                        dbHelper.getWritableDatabase().execSQL("UPDATE pending_uploads SET is_synced = 1 WHERE id = " + id);
                    }
                } catch (Exception e) {
                    Log.e("SyncWorker", "Upload sync error: " + e.getMessage());
                }
            }
        }
        cursor.close();
    }
}
