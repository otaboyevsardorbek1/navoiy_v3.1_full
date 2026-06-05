package com.prodevuzoff.alishernavoiyapp.network;

import android.content.Context;
import android.content.SharedPreferences;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKeys;
import com.prodevuzoff.alishernavoiyapp.BuildConfig;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import java.io.IOException;
import java.security.GeneralSecurityException;

public class NetworkClient {

    private static Retrofit retrofit = null;
    private static String lastBaseUrl = "";
    private static final String APP_SIGNATURE = "Navoiy_App_Secure_2024_v1";

    public static ApiService getApiService(Context context) {
        Context appContext = context.getApplicationContext();
        SharedPreferences settingsPrefs = appContext.getSharedPreferences("Settings", Context.MODE_PRIVATE);
        
        // Ngrok manzilingizni shu yerga default qilib qo'yish ham mumkin
        String baseUrl = settingsPrefs.getString("api_url", "https://c0a5-84-54-115-89.ngrok-free.app/api/v1/");
        
        if (!baseUrl.endsWith("/")) {
            baseUrl += "/";
        }

        // Agar URL o'zgargan bo'lsa, Retrofitni yangidan quramiz
        if (retrofit == null || !baseUrl.equals(lastBaseUrl)) {
            lastBaseUrl = baseUrl;
            
            HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
            logging.setLevel(BuildConfig.DEBUG ? HttpLoggingInterceptor.Level.BODY : HttpLoggingInterceptor.Level.NONE);

            OkHttpClient client = new OkHttpClient.Builder()
                    .addInterceptor(logging)
                    .addInterceptor(chain -> {
                        String token = getSecureToken(appContext);
                        Request.Builder builder = chain.request().newBuilder();
                        
                        // Ngrok browser ogohlantirishini chetlab o'tish uchun maxsus header
                        builder.addHeader("ngrok-skip-browser-warning", "true");
                        
                        builder.addHeader("X-App-Signature", APP_SIGNATURE);
                        builder.addHeader("X-App-Version", String.valueOf(BuildConfig.VERSION_CODE));
                        
                        if (token != null) {
                            builder.addHeader("Authorization", "Bearer " + token);
                        }
                        return chain.proceed(builder.build());
                    })
                    .build();

            retrofit = new Retrofit.Builder()
                    .baseUrl(baseUrl)
                    .addConverterFactory(GsonConverterFactory.create())
                    .client(client)
                    .build();
        }
        return retrofit.create(ApiService.class);
    }

    private static String getSecureToken(Context context) {
        try {
            String masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC);
            SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                    "secure_auth_prefs",
                    masterKeyAlias,
                    context,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            );
            return sharedPreferences.getString("access_token", null);
        } catch (GeneralSecurityException | IOException e) {
            return null;
        }
    }
}
