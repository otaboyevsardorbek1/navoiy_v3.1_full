package com.prodevuzoff.alishernavoiyapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.TextPaint;
import android.text.method.LinkMovementMethod;
import android.text.style.ClickableSpan;
import android.util.Log;
import android.util.TypedValue;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.prodevuzoff.alishernavoiyapp.database.AsarManager;
import com.prodevuzoff.alishernavoiyapp.database.DictionaryManager;
import com.prodevuzoff.alishernavoiyapp.database.ProgressManager;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.models.DictionaryTerm;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.requests.ProgressUpdateRequest;
import com.prodevuzoff.alishernavoiyapp.network.requests.QuizSubmitRequest;
import com.prodevuzoff.alishernavoiyapp.network.responses.QuizSubmitResult;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;
import com.prodevuzoff.alishernavoiyapp.utils.JsonUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AsarReaderActivity extends AppCompatActivity {

    private String asarSlug;
    private Asar asar;
    private int currentPageIndex = 0;
    private ProgressManager progressManager;
    private AsarManager asarManager;
    private DictionaryManager dictionaryManager;
    private float currentTextSize = 18f;

    private TextView textViewPageTitle, textViewContent, textViewPageIndicator, textViewQuizQuestion;
    private LinearLayout layoutQuiz;
    private RadioGroup radioGroupOptions;
    private Button buttonPrev, buttonNext, buttonSubmitQuiz;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        applyTheme();
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_asar_reader);

        asarSlug = getIntent().getStringExtra("asar_slug");
        progressManager = new ProgressManager(this);
        asarManager = new AsarManager(this);
        dictionaryManager = new DictionaryManager(this);

        initViews();
        loadAsarData();
        
        // Namuna uchun lug'atga so'z qo'shish (test uchun)
        if (dictionaryManager.getTerm("ko'ngul") == null) {
            dictionaryManager.addTerm(new DictionaryTerm("ko'ngul", "Qalb, yurak, ruh.", "Eski o'zbek tili"));
            dictionaryManager.addTerm(new DictionaryTerm("ishq", "Illohiy yoki dunyoviy kuchli muhabbat.", "Eski o'zbek tili"));
        }
    }

    private void initViews() {
        Toolbar toolbar = findViewById(R.id.toolbarReader);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        textViewPageTitle = findViewById(R.id.textViewPageTitle);
        textViewContent = findViewById(R.id.textViewContent);
        textViewPageIndicator = findViewById(R.id.textViewPageIndicator);
        textViewQuizQuestion = findViewById(R.id.textViewQuizQuestion);
        layoutQuiz = findViewById(R.id.layoutQuiz);
        radioGroupOptions = findViewById(R.id.radioGroupOptions);
        buttonPrev = findViewById(R.id.buttonPrev);
        buttonNext = findViewById(R.id.buttonNext);
        buttonSubmitQuiz = findViewById(R.id.buttonSubmitQuiz);
        progressBar = findViewById(R.id.progressBarReader);

        buttonPrev.setOnClickListener(v -> navigatePage(-1));
        buttonNext.setOnClickListener(v -> navigatePage(1));
        buttonSubmitQuiz.setOnClickListener(v -> checkAndSubmitQuiz());
        
        currentTextSize = getSharedPreferences("Settings", MODE_PRIVATE).getFloat("reader_text_size", 18f);
        updateTextSize();
        
        // Muhim: ClickableSpan ishlashi uchun
        textViewContent.setMovementMethod(LinkMovementMethod.getInstance());
    }

    private void loadAsarData() {
        setLoading(true);
        asar = asarManager.getAsarFull(asarSlug);
        
        if (asar != null) {
            onAsarLoaded();
        } else {
            NetworkClient.getApiService(this).downloadAsar(asarSlug).enqueue(new Callback<Asar>() {
                @Override
                public void onResponse(Call<Asar> call, Response<Asar> response) {
                    setLoading(false);
                    if (response.isSuccessful() && response.body() != null) {
                        asar = response.body();
                        asarManager.saveAsarFull(asar);
                        onAsarLoaded();
                    } else {
                        asar = JsonUtils.getAsarBySlug(AsarReaderActivity.this, asarSlug);
                        if (asar != null) {
                            onAsarLoaded();
                        } else {
                            ErrorUtils.showResponseError(AsarReaderActivity.this, response);
                        }
                    }
                }

                @Override
                public void onFailure(Call<Asar> call, Throwable t) {
                    setLoading(false);
                    asar = JsonUtils.getAsarBySlug(AsarReaderActivity.this, asarSlug);
                    if (asar != null) {
                        onAsarLoaded();
                    } else {
                        ErrorUtils.showErrorMessage(AsarReaderActivity.this, t);
                    }
                }
            });
        }
    }

    private void onAsarLoaded() {
        setLoading(false);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(asar.title);
        }
        currentPageIndex = progressManager.getSavedPage(asar.id);
        displayPage();
    }

    private void navigatePage(int delta) {
        if (delta == 0 || asar == null) return;
        int newIndex = currentPageIndex + delta;
        if (newIndex >= 0 && newIndex < asar.pages.size()) {
            currentPageIndex = newIndex;
            saveCurrentProgress();
            displayPage();
        }
    }

    private void displayPage() {
        if (asar == null || asar.pages == null || asar.pages.isEmpty()) return;

        Asar.AsarPage page = asar.pages.get(currentPageIndex);
        textViewPageTitle.setText(page.title);
        
        // Matnni lug'at bilan boyitish
        setupClickableText(page.content);
        
        textViewPageIndicator.setText((currentPageIndex + 1) + " / " + asar.pages.size());

        buttonPrev.setEnabled(currentPageIndex > 0);
        buttonNext.setEnabled(currentPageIndex < asar.pages.size() - 1);

        if (page.quizzes != null && !page.quizzes.isEmpty()) {
            layoutQuiz.setVisibility(View.VISIBLE);
            setupQuiz(page.quizzes.get(0));
        } else {
            layoutQuiz.setVisibility(View.GONE);
        }
    }

    private void setupClickableText(String content) {
        if (content == null) return;
        
        SpannableString spannableString = new SpannableString(content);
        // So'zlarni ajratish (faqat harf va ba'zi belgilarni olamiz)
        Pattern pattern = Pattern.compile("[\\w'‘’`]+", Pattern.UNICODE_CHARACTER_CLASS);
        Matcher matcher = pattern.matcher(content);

        while (matcher.find()) {
            final String word = matcher.group();
            ClickableSpan clickableSpan = new ClickableSpan() {
                @Override
                public void onClick(@NonNull View widget) {
                    checkDictionary(word);
                }

                @Override
                public void updateDrawState(@NonNull TextPaint ds) {
                    super.updateDrawState(ds);
                    ds.setUnderlineText(false); // Tagiga chizmaslik
                    ds.setColor(textViewContent.getCurrentTextColor()); // Matn rangi bilan bir xil
                }
            };
            spannableString.setSpan(clickableSpan, matcher.start(), matcher.end(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        
        textViewContent.setText(spannableString);
    }

    private void checkDictionary(String word) {
        // Lug'atdan qidirish
        DictionaryTerm term = dictionaryManager.getTerm(word);
        if (term != null) {
            showTermPopup(term);
        } else {
            // Agar lug'atda bo'lmasa, oddiy xabar yoki Google qidiruv taklif qilish mumkin
            Log.d("Dictionary", "So'z topilmadi: " + word);
        }
    }

    private void showTermPopup(DictionaryTerm term) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.Theme_AlisherNavoiyApp_Dialog);
        View view = getLayoutInflater().inflate(R.layout.dialog_dictionary_term, null);
        
        TextView tvTerm = view.findViewById(R.id.textViewTerm);
        TextView tvCategory = view.findViewById(R.id.textViewCategory);
        TextView tvDefinition = view.findViewById(R.id.textViewDefinition);
        
        tvTerm.setText(term.term);
        tvCategory.setText(term.category);
        tvDefinition.setText(term.definition);
        
        builder.setView(view);
        AlertDialog dialog = builder.create();
        dialog.show();
    }

    private void setupQuiz(Asar.Quiz quiz) {
        textViewQuizQuestion.setText(quiz.question);
        radioGroupOptions.removeAllViews();
        for (int i = 0; i < quiz.options.size(); i++) {
            RadioButton rb = new RadioButton(this);
            rb.setText(quiz.options.get(i));
            rb.setId(i);
            radioGroupOptions.addView(rb);
        }
        buttonSubmitQuiz.setEnabled(true);
    }

    private void checkAndSubmitQuiz() {
        int selectedId = radioGroupOptions.getCheckedRadioButtonId();
        if (selectedId == -1) {
            Toast.makeText(this, "Javobni tanlang", Toast.LENGTH_SHORT).show();
            return;
        }

        setLoading(true);
        Asar.AsarPage page = asar.pages.get(currentPageIndex);
        Asar.Quiz quiz = page.quizzes.get(0);

        List<Integer> selectedAnswers = new ArrayList<>();
        selectedAnswers.add(selectedId);
        QuizSubmitRequest request = new QuizSubmitRequest(quiz.id, selectedAnswers, 10);

        NetworkClient.getApiService(this).submitQuiz(request).enqueue(new Callback<QuizSubmitResult>() {
            @Override
            public void onResponse(Call<QuizSubmitResult> call, Response<QuizSubmitResult> response) {
                setLoading(false);
                if (response.isSuccessful() && response.body() != null) {
                    showQuizResult(response.body());
                } else {
                    ErrorUtils.showResponseError(AsarReaderActivity.this, response);
                }
            }

            @Override
            public void onFailure(Call<QuizSubmitResult> call, Throwable t) {
                setLoading(false);
                ErrorUtils.showErrorMessage(AsarReaderActivity.this, t);
            }
        });
    }

    private void showQuizResult(QuizSubmitResult result) {
        if (result.is_correct) {
            Toast.makeText(this, "To'g'ri! +" + result.points_earned + " ball", Toast.LENGTH_LONG).show();
            buttonSubmitQuiz.setEnabled(false);
        } else {
            Toast.makeText(this, "Noto'g'ri. " + result.explanation, Toast.LENGTH_LONG).show();
        }
    }

    private void saveCurrentProgress() {
        if (asar != null) {
            progressManager.saveProgress(asar.id, currentPageIndex, 0f);
            syncProgressWithServer();
        }
    }

    private void syncProgressWithServer() {
        ProgressUpdateRequest request = new ProgressUpdateRequest(
            asar.id,
            currentPageIndex + 1,
            0.0f, 
            currentPageIndex == asar.pages.size() - 1
        );

        NetworkClient.getApiService(this).syncReadProgress(request).enqueue(new Callback<Object>() {
            @Override
            public void onResponse(Call<Object> call, Response<Object> response) {
                if (response.isSuccessful()) Log.d("Sync", "Progress synced");
            }

            @Override
            public void onFailure(Call<Object> call, Throwable t) {
                Log.e("Sync", "Progress sync failed");
            }
        });
    }

    private void setLoading(boolean isLoading) {
        if (progressBar != null) progressBar.setVisibility(isLoading ? View.VISIBLE : View.GONE);
        buttonNext.setEnabled(!isLoading);
        buttonPrev.setEnabled(!isLoading);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_reader, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        int id = item.getItemId();
        if (id == R.id.action_zoom_in) {
            currentTextSize += 2;
            updateTextSize();
            return true;
        } else if (id == R.id.action_zoom_out) {
            if (currentTextSize > 12) currentTextSize -= 2;
            updateTextSize();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void updateTextSize() {
        textViewContent.setTextSize(TypedValue.COMPLEX_UNIT_SP, currentTextSize);
        getSharedPreferences("Settings", MODE_PRIVATE).edit().putFloat("reader_text_size", currentTextSize).apply();
    }

    private void applyTheme() {
        SharedPreferences prefs = getSharedPreferences("Settings", Context.MODE_PRIVATE);
        String theme = prefs.getString("app_theme", "classic");
        switch (theme) {
            case "modern": setTheme(R.style.Theme_AlisherNavoiyApp_Modern); break;
            case "dark": setTheme(R.style.Theme_AlisherNavoiyApp_Dark); break;
            default: setTheme(R.style.Theme_AlisherNavoiyApp_Classic); break;
        }
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }
}
