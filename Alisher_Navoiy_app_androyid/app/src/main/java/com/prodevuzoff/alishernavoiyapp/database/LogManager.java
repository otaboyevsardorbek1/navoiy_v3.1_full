package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.util.ArrayList;
import java.util.List;

public class LogManager {
    private final DatabaseHelper dbHelper;

    public LogManager(Context context) {
        dbHelper = new DatabaseHelper(context);
    }

    public void addLog(String type, String content) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("type", type);
        values.put("content", content);
        db.insert("logs", null, values);
    }

    public List<AppLog> getUnsentLogs() {
        List<AppLog> logs = new ArrayList<>();
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = db.query("logs", null, null, null, null, null, "timestamp ASC");
        if (cursor != null && cursor.moveToFirst()) {
            do {
                AppLog log = new AppLog();
                log.id = cursor.getInt(cursor.getColumnIndexOrThrow("id"));
                log.type = cursor.getString(cursor.getColumnIndexOrThrow("type"));
                log.content = cursor.getString(cursor.getColumnIndexOrThrow("content"));
                log.timestamp = cursor.getString(cursor.getColumnIndexOrThrow("timestamp"));
                logs.add(log);
            } while (cursor.moveToNext());
            cursor.close();
        }
        return logs;
    }

    public void deleteLog(int id) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        db.delete("logs", "id = ?", new String[]{String.valueOf(id)});
    }

    public static class AppLog {
        public int id;
        public String type;
        public String content;
        public String timestamp;
    }
}
