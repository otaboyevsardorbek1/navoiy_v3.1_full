package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import com.google.gson.Gson;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.models.ManifestItem;
import java.util.ArrayList;
import java.util.List;

public class AsarManager {
    private final DatabaseHelper dbHelper;
    private final Gson gson;

    public AsarManager(Context context) {
        dbHelper = new DatabaseHelper(context);
        gson = new Gson();
    }

    public void saveAsarFull(Asar asar) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        db.beginTransaction();
        try {
            ContentValues values = new ContentValues();
            values.put("asar_id", asar.id);
            values.put("slug", asar.slug);
            values.put("title_uz", asar.title_uz != null ? asar.title_uz : asar.title);
            values.put("category", asar.category);
            values.put("total_pages", asar.total_pages);
            values.put("version", asar.version);
            values.put("is_downloaded", 1);
            values.put("checksum", asar.checksum);
            db.insertWithOnConflict("asarlar", null, values, SQLiteDatabase.CONFLICT_REPLACE);

            if (asar.pages != null) {
                db.delete("asar_pages", "asar_id=?", new String[]{String.valueOf(asar.id)});
                for (Asar.AsarPage page : asar.pages) {
                    ContentValues pageValues = new ContentValues();
                    pageValues.put("asar_id", asar.id);
                    pageValues.put("page_number", page.page_number);
                    pageValues.put("title", page.title);
                    pageValues.put("content", page.content);
                    pageValues.put("word_count", page.word_count);
                    db.insert("asar_pages", null, pageValues);

                    if (page.quizzes != null) {
                        for (Asar.Quiz quiz : page.quizzes) {
                            ContentValues qv = new ContentValues();
                            qv.put("id", quiz.id);
                            qv.put("asar_id", asar.id);
                            qv.put("page_number", page.page_number);
                            qv.put("question", quiz.question);
                            qv.put("options", gson.toJson(quiz.options));
                            qv.put("correct_answers", gson.toJson(quiz.correct_answers));
                            qv.put("explanation", quiz.explanation);
                            qv.put("points", quiz.points);
                            db.insertWithOnConflict("quizzes", null, qv, SQLiteDatabase.CONFLICT_REPLACE);
                        }
                    }
                }
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
            db.close();
        }
    }

    public Asar getAsarFull(String slug) {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Asar asar = null;
        Cursor cursor = null;
        try {
            cursor = db.query("asarlar", null, "slug=?", new String[]{slug}, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                asar = new Asar();
                asar.id = cursor.getInt(cursor.getColumnIndexOrThrow("asar_id"));
                asar.slug = cursor.getString(cursor.getColumnIndexOrThrow("slug"));
                asar.title = cursor.getString(cursor.getColumnIndexOrThrow("title_uz"));
                asar.category = cursor.getString(cursor.getColumnIndexOrThrow("category"));
                asar.total_pages = cursor.getInt(cursor.getColumnIndexOrThrow("total_pages"));
                asar.version = cursor.getInt(cursor.getColumnIndexOrThrow("version"));

                asar.pages = new ArrayList<>();
                Cursor pc = db.query("asar_pages", null, "asar_id=?", new String[]{String.valueOf(asar.id)}, null, null, "page_number ASC");
                if (pc != null && pc.moveToFirst()) {
                    do {
                        Asar.AsarPage page = new Asar.AsarPage();
                        page.page_number = pc.getInt(pc.getColumnIndexOrThrow("page_number"));
                        page.title = pc.getString(pc.getColumnIndexOrThrow("title"));
                        page.content = pc.getString(pc.getColumnIndexOrThrow("content"));
                        page.word_count = pc.getInt(pc.getColumnIndexOrThrow("word_count"));

                        page.quizzes = new ArrayList<>();
                        Cursor qc = db.query("quizzes", null, "asar_id=? AND page_number=?", 
                                new String[]{String.valueOf(asar.id), String.valueOf(page.page_number)}, null, null, null);
                        if (qc != null && qc.moveToFirst()) {
                            do {
                                Asar.Quiz quiz = new Asar.Quiz();
                                quiz.id = qc.getInt(qc.getColumnIndexOrThrow("id"));
                                quiz.question = qc.getString(qc.getColumnIndexOrThrow("question"));
                                quiz.explanation = qc.getString(qc.getColumnIndexOrThrow("explanation"));
                                quiz.points = qc.getInt(qc.getColumnIndexOrThrow("points"));
                                quiz.options = gson.fromJson(qc.getString(qc.getColumnIndexOrThrow("options")), new com.google.gson.reflect.TypeToken<List<String>>(){}.getType());
                                quiz.correct_answers = gson.fromJson(qc.getString(qc.getColumnIndexOrThrow("correct_answers")), new com.google.gson.reflect.TypeToken<List<Integer>>(){}.getType());
                                page.quizzes.add(quiz);
                            } while (qc.moveToNext());
                            qc.close();
                        }
                        asar.pages.add(page);
                    } while (pc.moveToNext());
                    pc.close();
                }
            }
        } finally {
            if (cursor != null) cursor.close();
            db.close();
        }
        return asar;
    }

    public List<ManifestItem> getDownloadedAsarlar() {
        List<ManifestItem> items = new ArrayList<>();
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = null;
        try {
            cursor = db.query("asarlar", null, "is_downloaded=1", null, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                do {
                    ManifestItem item = new ManifestItem();
                    item.id = cursor.getInt(cursor.getColumnIndexOrThrow("asar_id"));
                    item.slug = cursor.getString(cursor.getColumnIndexOrThrow("slug"));
                    item.title_uz = cursor.getString(cursor.getColumnIndexOrThrow("title_uz"));
                    item.total_pages = cursor.getInt(cursor.getColumnIndexOrThrow("total_pages"));
                    item.version = cursor.getInt(cursor.getColumnIndexOrThrow("version"));
                    item.is_downloaded = true;
                    items.add(item);
                } while (cursor.moveToNext());
            }
        } finally {
            if (cursor != null) cursor.close();
            db.close();
        }
        return items;
    }

    public boolean isAsarDownloaded(String slug) {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = null;
        boolean exists = false;
        try {
            cursor = db.query("asarlar", new String[]{"asar_id"}, "slug=? AND is_downloaded=1", new String[]{slug}, null, null, null);
            exists = cursor != null && cursor.getCount() > 0;
        } finally {
            if (cursor != null) cursor.close();
            db.close();
        }
        return exists;
    }

    public void deleteAsar(String slug) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        db.beginTransaction();
        try {
            Cursor cursor = db.query("asarlar", new String[]{"asar_id"}, "slug=?", new String[]{slug}, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                int asarId = cursor.getInt(0);
                cursor.close();
                db.delete("quizzes", "asar_id=?", new String[]{String.valueOf(asarId)});
                db.delete("asar_pages", "asar_id=?", new String[]{String.valueOf(asarId)});
                db.delete("asarlar", "asar_id=?", new String[]{String.valueOf(asarId)});
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
            db.close();
        }
    }

    public void deleteAllDownloadedAsarlar() {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        db.beginTransaction();
        try {
            db.delete("quizzes", null, null);
            db.delete("asar_pages", null, null);
            db.delete("asarlar", "is_downloaded=1", null);
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
            db.close();
        }
    }
}
