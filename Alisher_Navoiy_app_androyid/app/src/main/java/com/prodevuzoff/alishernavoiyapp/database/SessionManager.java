package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKeys;
import com.google.gson.Gson;
import java.io.IOException;
import java.security.GeneralSecurityException;

public class SessionManager {
    private SharedPreferences authPrefs;
    private final DatabaseHelper dbHelper;
    private final Gson gson;

    public SessionManager(Context context) {
        this.dbHelper = new DatabaseHelper(context);
        this.gson = new Gson();
        try {
            String masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC);
            this.authPrefs = EncryptedSharedPreferences.create(
                    "secure_auth_prefs",
                    masterKeyAlias,
                    context,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            );
        } catch (GeneralSecurityException | IOException e) {
            this.authPrefs = context.getSharedPreferences("Auth", Context.MODE_PRIVATE);
        }
    }

    public void startSession(int userId, String username, String role, String token) {
        authPrefs.edit()
            .putInt("user_id", userId)
            .putString("username", username)
            .putString("role", role)
            .putString("access_token", token)
            .putBoolean("is_logged_in", true)
            .putLong("login_time", System.currentTimeMillis())
            .apply();

        logActivity(userId, "LOGIN", "Foydalanuvchi tizimga kirdi: " + username);
    }

    public void endSession() {
        int userId = authPrefs.getInt("user_id", -1);
        String username = authPrefs.getString("username", "unknown");

        logActivity(userId, "LOGOUT", "Foydalanuvchi tizimdan chiqdi: " + username);

        authPrefs.edit().clear().apply();
    }

    public void logActivity(int userId, String type, String details) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("user_id", userId);
        values.put("action_type", type);
        values.put("details", details);
        values.put("is_synced", 0);
        db.insert("session_activity_logs", null, values);
        db.close();
    }

    public void queueOfflineUpload(String type, Object data) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("upload_type", type);
        values.put("data_json", gson.toJson(data));
        values.put("is_synced", 0);
        db.insert("pending_uploads", null, values);
        db.close();
    }

    public boolean isLoggedIn() {
        return authPrefs.getBoolean("is_logged_in", false);
    }

    public String getUserRole() {
        return authPrefs.getString("role", "user");
    }

    public String getAccessToken() {
        return authPrefs.getString("access_token", null);
    }
}
