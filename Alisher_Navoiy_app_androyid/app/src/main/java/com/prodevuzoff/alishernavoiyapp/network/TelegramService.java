package com.prodevuzoff.alishernavoiyapp.network;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Path;
import retrofit2.http.Query;

public interface TelegramService {
    @GET("bot{token}/sendMessage")
    Call<ResponseBody> sendMessage(
            @Path("token") String token,
            @Query("chat_id") String chatId,
            @Query("text") String text,
            @Query("parse_mode") String parseMode
    );
}
