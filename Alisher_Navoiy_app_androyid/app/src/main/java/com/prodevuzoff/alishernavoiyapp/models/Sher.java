package com.prodevuzoff.alishernavoiyapp.models;

import com.google.gson.annotations.SerializedName;

public class Sher {
    public int id;
    public String slug;
    public String title;
    public String content;
    public String type;
    
    @SerializedName("description")
    public String description;
    
    @SerializedName("audio_url")
    public String audioUrl;
    
    @SerializedName("like_count")
    public int likeCount;
    
    @SerializedName("version")
    public int version;
    
    @SerializedName("is_favorite")
    public boolean isFavorite;
}
