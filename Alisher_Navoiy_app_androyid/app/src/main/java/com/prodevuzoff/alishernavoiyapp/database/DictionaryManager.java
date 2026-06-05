package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import com.prodevuzoff.alishernavoiyapp.models.DictionaryTerm;
import java.util.ArrayList;
import java.util.List;

public class DictionaryManager {
    private final DatabaseHelper dbHelper;

    public DictionaryManager(Context context) {
        dbHelper = new DatabaseHelper(context);
    }

    public void addTerm(DictionaryTerm term) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        try {
            ContentValues values = new ContentValues();
            values.put("term", term.term.toLowerCase().trim());
            values.put("definition", term.definition);
            values.put("category", term.category);
            db.insertWithOnConflict("dictionary", null, values, SQLiteDatabase.CONFLICT_REPLACE);
        } finally {
            db.close();
        }
    }

    public DictionaryTerm getTerm(String word) {
        if (word == null || word.isEmpty()) return null;
        
        // Punctuationni tozalash (Senior approach)
        String cleanedWord = word.toLowerCase().replaceAll("[^a-z'‘’`ʻа-яё]", "").trim();
        
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        DictionaryTerm term = null;
        Cursor cursor = null;
        try {
            cursor = db.query("dictionary", null, "term = ?", new String[]{cleanedWord}, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                term = new DictionaryTerm();
                term.id = cursor.getInt(cursor.getColumnIndexOrThrow("id"));
                term.term = cursor.getString(cursor.getColumnIndexOrThrow("term"));
                term.definition = cursor.getString(cursor.getColumnIndexOrThrow("definition"));
                term.category = cursor.getString(cursor.getColumnIndexOrThrow("category"));
            }
        } finally {
            if (cursor != null) cursor.close();
            db.close();
        }
        return term;
    }

    public void addInitialTerms(List<DictionaryTerm> terms) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        db.beginTransaction();
        try {
            for (DictionaryTerm term : terms) {
                ContentValues values = new ContentValues();
                values.put("term", term.term.toLowerCase().trim());
                values.put("definition", term.definition);
                values.put("category", term.category);
                db.insertWithOnConflict("dictionary", null, values, SQLiteDatabase.CONFLICT_REPLACE);
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
            db.close();
        }
    }
}
