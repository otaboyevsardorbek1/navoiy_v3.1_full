package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import com.prodevuzoff.alishernavoiyapp.models.Sher;
import java.util.ArrayList;
import java.util.List;

public class SherManager {
    private final DatabaseHelper dbHelper;

    public SherManager(Context context) {
        dbHelper = new DatabaseHelper(context);
    }

    public void saveSherlar(List<Sher> sherlar) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        db.beginTransaction();
        try {
            for (Sher sher : sherlar) {
                ContentValues values = new ContentValues();
                values.put("id", sher.id);
                values.put("slug", sher.slug);
                values.put("title", sher.title);
                values.put("content", sher.content);
                values.put("type", sher.type);
                values.put("is_favorite", sher.isFavorite ? 1 : 0);
                values.put("like_count", sher.likeCount);
                values.put("version", sher.version);
                db.insertWithOnConflict("sherlar", null, values, SQLiteDatabase.CONFLICT_REPLACE);
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
            db.close();
        }
    }

    public List<Sher> getAllSherlar() {
        List<Sher> sherlar = new ArrayList<>();
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = null;
        try {
            cursor = db.query("sherlar", null, null, null, null, null, "id ASC");
            if (cursor != null && cursor.moveToFirst()) {
                do {
                    Sher sher = new Sher();
                    sher.id = cursor.getInt(cursor.getColumnIndexOrThrow("id"));
                    sher.slug = cursor.getString(cursor.getColumnIndexOrThrow("slug"));
                    sher.title = cursor.getString(cursor.getColumnIndexOrThrow("title"));
                    sher.content = cursor.getString(cursor.getColumnIndexOrThrow("content"));
                    sher.type = cursor.getString(cursor.getColumnIndexOrThrow("type"));
                    sher.isFavorite = cursor.getInt(cursor.getColumnIndexOrThrow("is_favorite")) == 1;
                    sher.likeCount = cursor.getInt(cursor.getColumnIndexOrThrow("like_count"));
                    sher.version = cursor.getInt(cursor.getColumnIndexOrThrow("version"));
                    sherlar.add(sher);
                } while (cursor.moveToNext());
            }
        } finally {
            if (cursor != null) cursor.close();
            db.close();
        }
        return sherlar;
    }

    public void deleteAllSherlar() {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        try {
            db.delete("sherlar", null, null);
        } finally {
            db.close();
        }
    }
}
