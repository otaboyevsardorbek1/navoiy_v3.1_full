package com.prodevuzoff.alishernavoiyapp;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.prodevuzoff.alishernavoiyapp.database.DatabaseHelper;
import com.prodevuzoff.alishernavoiyapp.database.DictionaryManager;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.models.DictionaryTerm;
import com.prodevuzoff.alishernavoiyapp.models.Sher;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;

import java.util.Arrays;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AdminActivity extends AppCompatActivity {

    private DictionaryManager dictionaryManager;
    private DatabaseHelper dbHelper;
    private TextView tvStatAsarlar, tvStatSherlar, tvStatTerms;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin);

        dictionaryManager = new DictionaryManager(this);
        dbHelper = new DatabaseHelper(this);

        initViews();
        updateStats();
    }

    private void initViews() {
        Toolbar toolbar = findViewById(R.id.toolbarAdmin);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        tvStatAsarlar = findViewById(R.id.tvStatAsarlar);
        tvStatSherlar = findViewById(R.id.tvStatSherlar);
        tvStatTerms = findViewById(R.id.tvStatTerms);

        // Barcha qo'shish amallari uchun bitta tugma
        Button btnAdd = findViewById(R.id.btnAddNewTerm);
        btnAdd.setText("Yangi Ma'lumot Qo'shish");
        btnAdd.setOnClickListener(v -> showUnifiedAddDialog());
        
        findViewById(R.id.btnManageAsarlar).setVisibility(View.GONE);
        findViewById(R.id.btnManageSherlar).setVisibility(View.GONE);
    }

    private void showUnifiedAddDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_unified_add, null);
        
        Spinner spinner = view.findViewById(R.id.spinnerDataType);
        LinearLayout layoutAsar = view.findViewById(R.id.layoutAsarFields);
        LinearLayout layoutSher = view.findViewById(R.id.layoutSherFields);
        LinearLayout layoutQuiz = view.findViewById(R.id.layoutQuizFields);
        LinearLayout layoutDict = view.findViewById(R.id.layoutDictFields);

        spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                layoutAsar.setVisibility(position == 0 ? View.VISIBLE : View.GONE);
                layoutSher.setVisibility(position == 1 ? View.VISIBLE : View.GONE);
                layoutQuiz.setVisibility(position == 2 ? View.VISIBLE : View.GONE);
                layoutDict.setVisibility(position == 3 ? View.VISIBLE : View.GONE);
            }
            @Override public void onNothingSelected(AdapterView<?> parent) {}
        });

        builder.setView(view)
               .setPositiveButton("Saqlash", (dialog, which) -> {
                   int pos = spinner.getSelectedItemPosition();
                   if (pos == 0) handleAddAsar(view);
                   else if (pos == 1) handleAddSher(view);
                   else if (pos == 2) handleAddQuiz(view);
                   else if (pos == 3) handleAddDict(view);
               })
               .setNegativeButton("Bekor qilish", null)
               .show();
    }

    private void handleAddAsar(View v) {
        Asar asar = new Asar();
        asar.title = ((EditText)v.findViewById(R.id.etAsarTitle)).getText().toString();
        asar.slug = ((EditText)v.findViewById(R.id.etAsarSlug)).getText().toString();
        asar.category = ((EditText)v.findViewById(R.id.etAsarCategory)).getText().toString();
        asar.description = ((EditText)v.findViewById(R.id.etAsarDescription)).getText().toString();

        NetworkClient.getApiService(this).createAsar(asar).enqueue(new SimpleCallback<>("Asar"));
    }

    private void handleAddSher(View v) {
        Sher sher = new Sher();
        sher.title = ((EditText)v.findViewById(R.id.etSherTitle)).getText().toString();
        sher.content = ((EditText)v.findViewById(R.id.etSherContent)).getText().toString();
        sher.type = ((EditText)v.findViewById(R.id.etSherType)).getText().toString();
        sher.slug = sher.title.toLowerCase().replace(" ", "-");

        NetworkClient.getApiService(this).createSher(sher).enqueue(new SimpleCallback<>("She'r"));
    }

    private void handleAddQuiz(View v) {
        String slug = ((EditText)v.findViewById(R.id.etQuizAsarSlug)).getText().toString();
        Asar.Quiz quiz = new Asar.Quiz();
        quiz.question = ((EditText)v.findViewById(R.id.etQuizQuestion)).getText().toString();
        String optionsStr = ((EditText)v.findViewById(R.id.etQuizOptions)).getText().toString();
        quiz.options = Arrays.asList(optionsStr.split(","));
        quiz.correct_answers = Arrays.asList(Integer.parseInt(((EditText)v.findViewById(R.id.etQuizCorrect)).getText().toString()));
        
        // Quiz asar ichida bo'lgani uchun odatda updateAsar ishlatiladi yoki alohida API bo'lishi kerak
        Toast.makeText(this, "Quiz qo'shish uchun asarni yangilash lozim", Toast.LENGTH_SHORT).show();
    }

    private void handleAddDict(View v) {
        String term = ((EditText)v.findViewById(R.id.etDictTerm)).getText().toString();
        String def = ((EditText)v.findViewById(R.id.etDictDefinition)).getText().toString();
        dictionaryManager.addTerm(new DictionaryTerm(term, def, "Umumiy"));
        Toast.makeText(this, "So'z lug'atga qo'shildi", Toast.LENGTH_SHORT).show();
        updateStats();
    }

    private class SimpleCallback<T> implements Callback<T> {
        private String type;
        public SimpleCallback(String type) { this.type = type; }
        @Override
        public void onResponse(Call<T> call, Response<T> response) {
            if (response.isSuccessful()) {
                Toast.makeText(AdminActivity.this, type + " muvaffaqiyatli saqlandi", Toast.LENGTH_SHORT).show();
                updateStats();
            } else Toast.makeText(AdminActivity.this, "Xatolik: " + response.code(), Toast.LENGTH_SHORT).show();
        }
        @Override
        public void onFailure(Call<T> call, Throwable t) {
            Toast.makeText(AdminActivity.this, "Tarmoq xatosi", Toast.LENGTH_SHORT).show();
        }
    }

    private void updateStats() {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        tvStatAsarlar.setText("Jami asarlar: " + getCount(db, "asarlar"));
        tvStatSherlar.setText("Jami she'rlar: " + getCount(db, "sherlar"));
        tvStatTerms.setText("Lug'at boyligi: " + getCount(db, "dictionary"));
    }

    private long getCount(SQLiteDatabase db, String table) {
        Cursor cursor = db.rawQuery("SELECT COUNT(*) FROM " + table, null);
        long count = 0;
        if (cursor.moveToFirst()) count = cursor.getLong(0);
        cursor.close();
        return count;
    }

    @Override public boolean onSupportNavigateUp() { onBackPressed(); return true; }
}
