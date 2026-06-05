package com.prodevuzoff.alishernavoiyapp.utils;

import android.content.Context;
import android.widget.Toast;

import java.io.IOException;
import java.net.ConnectException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;

import retrofit2.Response;

public class ErrorUtils {

    public static void showErrorMessage(Context context, Throwable t) {
        if (context == null) return;
        
        String message;
        if (t instanceof UnknownHostException || t instanceof ConnectException) {
            message = "Internet aloqasi yo'q yoki server manzili noto'g'ri. Sozlamalardan API URLni tekshiring.";
        } else if (t instanceof SocketTimeoutException) {
            message = "Server javob berishi juda uzoq davom etdi. Iltimos, qaytadan urinib ko'ring.";
        } else if (t instanceof IOException) {
            message = "Ma'lumotlarni o'qishda xatolik yuz berdi.";
        } else {
            message = "Kutilmagan xatolik: " + t.getLocalizedMessage();
        }
        Toast.makeText(context.getApplicationContext(), message, Toast.LENGTH_LONG).show();
    }

    public static void showResponseError(Context context, Response<?> response) {
        if (context == null) return;

        String message;
        switch (response.code()) {
            case 400:
                message = "Noto'g'ri so'rov yuborildi.";
                break;
            case 401:
                message = "Avtorizatsiya xatosi. Iltimos, qaytadan tizimga kiring.";
                break;
            case 403:
                message = "Sizda ushbu amalni bajarish uchun ruxsat yo'q.";
                break;
            case 404:
                message = "So'ralgan ma'lumot topilmadi.";
                break;
            case 500:
                message = "Serverda ichki xatolik yuz berdi. Keyinroq urinib ko'ring.";
                break;
            default:
                message = "Xatolik kodi: " + response.code();
                break;
        }
        Toast.makeText(context.getApplicationContext(), message, Toast.LENGTH_SHORT).show();
    }
}
