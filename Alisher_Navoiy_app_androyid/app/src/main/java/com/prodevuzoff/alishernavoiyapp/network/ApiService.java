package com.prodevuzoff.alishernavoiyapp.network;

import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.models.Sher;
import com.prodevuzoff.alishernavoiyapp.network.requests.ForgotPasswordRequest;
import com.prodevuzoff.alishernavoiyapp.network.requests.LoginRequest;
import com.prodevuzoff.alishernavoiyapp.network.requests.ProgressUpdateRequest;
import com.prodevuzoff.alishernavoiyapp.network.requests.QuizSubmitRequest;
import com.prodevuzoff.alishernavoiyapp.network.requests.RegisterRequest;
import com.prodevuzoff.alishernavoiyapp.network.responses.AppConfigResponse;
import com.prodevuzoff.alishernavoiyapp.network.responses.LeaderboardResponse;
import com.prodevuzoff.alishernavoiyapp.network.responses.QuizSubmitResult;
import com.prodevuzoff.alishernavoiyapp.network.responses.SyncManifestResponse;
import com.prodevuzoff.alishernavoiyapp.network.responses.TokenResponse;
import com.prodevuzoff.alishernavoiyapp.network.responses.UserStatsResponse;

import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Path;
import retrofit2.http.Query;

public interface ApiService {
    @POST("auth/login")
    Call<TokenResponse> login(@Body LoginRequest request);

    @POST("auth/register")
    Call<TokenResponse> register(@Body RegisterRequest request);

    @POST("auth/reset-password")
    Call<Object> resetPassword(@Body ForgotPasswordRequest request);

    @GET("asarlar")
    Call<Map<String, Object>> getAsarlar(@Query("page") int page, @Query("limit") int limit);

    @POST("asarlar")
    Call<Asar> createAsar(@Body Asar asar);

    @PUT("asarlar/{slug}")
    Call<Asar> updateAsar(@Path("slug") String slug, @Body Asar asar);

    @DELETE("asarlar/{slug}")
    Call<Object> deleteAsar(@Path("slug") String slug);

    @GET("asarlar/{slug}/content")
    Call<Asar> downloadAsar(@Path("slug") String slug);

    @POST("asarlar/{slug}/content")
    Call<Map<String, Object>> uploadAsarContent(@Path("slug") String slug, @Body Asar content);

    @GET("sherlar")
    Call<PaginatedResponse<Sher>> getSherlar(@Query("page") int page, @Query("limit") int limit);

    @POST("sherlar")
    Call<Sher> createSher(@Body Sher sher);

    @PUT("sherlar/{slug}")
    Call<Sher> updateSher(@Path("slug") String slug, @Body Sher sher);

    @DELETE("sherlar/{slug}")
    Call<Object> deleteSher(@Path("slug") String slug);

    @POST("quiz/submit")
    Call<QuizSubmitResult> submitQuiz(@Body QuizSubmitRequest request);

    @POST("sync/progress")
    Call<Object> syncReadProgress(@Body ProgressUpdateRequest request);

    @GET("admin/settings")
    Call<Map<String, String>> getAdminSettings();

    @POST("admin/settings")
    Call<Object> updateAdminSetting(@Query("key") String key, @Query("value") String value);

    @POST("logs/auth-log")
    Call<Object> sendActivityLog(@Body Map<String, Object> logData);

    @POST("logs/auth-log")
    Call<Object> sendAuthLog(@Body Map<String, String> logData);

    @GET("sync/manifest")
    Call<SyncManifestResponse> getSyncManifest();

    @GET("leaderboard")
    Call<LeaderboardResponse> getLeaderboard();

    @GET("user/stats")
    Call<UserStatsResponse> getUserStats();

    @GET("config")
    Call<AppConfigResponse> getAppConfig();

    class PaginatedResponse<T> {
        public List<T> items;
        public int total;
        public int page;
        public int limit;
    }
}
