package com.prodevuzoff.alishernavoiyapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

public class DatabaseHelper extends SQLiteOpenHelper {

    private static final String DATABASE_NAME = "navoiy_db";
    private static final int DATABASE_VERSION = 7;

    public DatabaseHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE asarlar (" +
                "asar_id INTEGER PRIMARY KEY, " +
                "slug TEXT UNIQUE, " +
                "title_uz TEXT, " +
                "category TEXT, " +
                "total_pages INTEGER, " +
                "version INTEGER, " +
                "is_downloaded INTEGER DEFAULT 0, " +
                "checksum TEXT)");

        db.execSQL("CREATE TABLE asar_pages (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "asar_id INTEGER, " +
                "page_number INTEGER, " +
                "title TEXT, " +
                "content TEXT, " +
                "word_count INTEGER, " +
                "FOREIGN KEY(asar_id) REFERENCES asarlar(asar_id) ON DELETE CASCADE)");

        db.execSQL("CREATE TABLE quizzes (" +
                "id INTEGER PRIMARY KEY, " +
                "asar_id INTEGER, " +
                "page_number INTEGER, " +
                "question TEXT, " +
                "options TEXT, " +
                "correct_answers TEXT, " +
                "explanation TEXT, " +
                "points INTEGER)");

        db.execSQL("CREATE TABLE sherlar (" +
                "id INTEGER PRIMARY KEY, " +
                "slug TEXT UNIQUE, " +
                "title TEXT, " +
                "content TEXT, " +
                "type TEXT, " +
                "is_favorite INTEGER DEFAULT 0, " +
                "like_count INTEGER DEFAULT 0, " +
                "version INTEGER)");

        db.execSQL("CREATE TABLE read_progress (" +
                "asar_id INTEGER PRIMARY KEY, " +
                "current_page INTEGER, " +
                "scroll_offset REAL, " +
                "is_completed INTEGER DEFAULT 0, " +
                "is_synced INTEGER DEFAULT 0)");

        db.execSQL("CREATE TABLE sync_meta (" +
                "key TEXT PRIMARY KEY, " +
                "value TEXT)");

        db.execSQL("CREATE TABLE logs (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "type TEXT, " +
                "content TEXT, " +
                "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE dictionary (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "term TEXT UNIQUE, " +
                "definition TEXT, " +
                "category TEXT)");

        // Yangi: Sessiya loglari (Login/Logout va foydalanuvchi harakatlari)
        db.execSQL("CREATE TABLE session_activity_logs (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "user_id INTEGER, " +
                "action_type TEXT, " +
                "details TEXT, " +
                "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, " +
                "is_synced INTEGER DEFAULT 0)");

        // Yangi: Offline kiritilgan asarlar (Admin uchun)
        db.execSQL("CREATE TABLE pending_uploads (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "upload_type TEXT, " +
                "data_json TEXT, " +
                "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, " +
                "is_synced INTEGER DEFAULT 0)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        if (oldVersion < 6) {
            db.execSQL("CREATE TABLE IF NOT EXISTS dictionary (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "term TEXT UNIQUE, " +
                    "definition TEXT, " +
                    "category TEXT)");
        }
        if (oldVersion < 7) {
            db.execSQL("CREATE TABLE IF NOT EXISTS session_activity_logs (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "user_id INTEGER, " +
                    "action_type TEXT, " +
                    "details TEXT, " +
                    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, " +
                    "is_synced INTEGER DEFAULT 0)");
            
            db.execSQL("CREATE TABLE IF NOT EXISTS pending_uploads (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "upload_type TEXT, " +
                    "data_json TEXT, " +
                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, " +
                    "is_synced INTEGER DEFAULT 0)");
        }
    }
}
