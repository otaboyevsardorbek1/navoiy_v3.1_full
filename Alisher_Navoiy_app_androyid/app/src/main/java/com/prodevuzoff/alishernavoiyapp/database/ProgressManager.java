package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

public class ProgressManager {

    private final DatabaseHelper dbHelper;

    public ProgressManager(Context context) {
        dbHelper = new DatabaseHelper(context);
    }

    public void saveProgress(int asarId, int page, float scrollOffset) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        try {
            ContentValues values = new ContentValues();
            values.put("asar_id", asarId);
            values.put("current_page", page);
            values.put("scroll_offset", scrollOffset);
            values.put("is_synced", 0);

            db.insertWithOnConflict("read_progress", null, values, SQLiteDatabase.CONFLICT_REPLACE);
        } finally {
            db.close();
        }
    }

    public int getSavedPage(int asarId) {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = null;
        try {
            cursor = db.query("read_progress", new String[]{"current_page"}, "asar_id=?", new String[]{String.valueOf(asarId)}, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                return cursor.getInt(0);
            }
        } finally {
            if (cursor != null) cursor.close();
            db.close();
        }
        return 0;
    }
}