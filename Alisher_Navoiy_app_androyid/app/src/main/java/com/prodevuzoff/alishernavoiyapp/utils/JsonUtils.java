package com.prodevuzoff.alishernavoiyapp.utils;

import android.content.Context;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.models.ManifestItem;
import com.prodevuzoff.alishernavoiyapp.models.Sher;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

public class JsonUtils {

    public static String loadJSONFromAsset(Context context, String fileName) {
        String json;
        try {
            InputStream is = context.getAssets().open(fileName);
            int size = is.available();
            byte[] buffer = new byte[size];
            is.read(buffer);
            is.close();
            json = new String(buffer, StandardCharsets.UTF_8);
        } catch (IOException ex) {
            ex.printStackTrace();
            return null;
        }
        return json;
    }

    public static List<ManifestItem> getManifest(Context context) {
        String json = loadJSONFromAsset(context, "data/manifest.json");
        if (json == null) return new ArrayList<>();
        Type listType = new TypeToken<List<ManifestItem>>() {}.getType();
        return new Gson().fromJson(json, listType);
    }

    public static Asar getAsarBySlug(Context context, String slug) {
        String json = loadJSONFromAsset(context, "data/asarlar/" + slug + ".json");
        if (json == null) return null;
        return new Gson().fromJson(json, Asar.class);
    }

    public static List<Sher> getSherlar(Context context) {
        String json = loadJSONFromAsset(context, "data/sherlar.json");
        if (json == null) return new ArrayList<>();
        Type listType = new TypeToken<List<Sher>>() {}.getType();
        return new Gson().fromJson(json, listType);
    }
}