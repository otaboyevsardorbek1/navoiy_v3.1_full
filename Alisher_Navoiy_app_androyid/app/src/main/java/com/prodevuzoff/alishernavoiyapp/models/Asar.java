package com.prodevuzoff.alishernavoiyapp.models;

import com.google.gson.annotations.SerializedName;
import java.util.List;

public class Asar {
    @SerializedName("id")
    public int id;
    
    @SerializedName("title")
    public String title;
    
    @SerializedName("title_uz")
    public String title_uz;
    
    @SerializedName("slug")
    public String slug;
    
    @SerializedName("description")
    public String description;
    
    @SerializedName("category")
    public String category;
    
    @SerializedName("image_url")
    public String image_url;
    
    @SerializedName("year")
    public Integer year;
    
    @SerializedName("language")
    public String language;
    
    @SerializedName("tags")
    public List<String> tags;
    
    @SerializedName("read_count")
    public int read_count;
    
    @SerializedName("total_pages")
    public int total_pages;
    
    @SerializedName("version")
    public int version;
    
    @SerializedName("checksum")
    public String checksum;
    
    @SerializedName("is_published")
    public boolean is_published;
    
    @SerializedName("updated_at")
    public String updated_at;
    
    @SerializedName("created_at")
    public String created_at;
    
    @SerializedName("pages")
    public List<AsarPage> pages;

    public static class AsarPageMeta {
        public int id;
        public int page_number;
        public String title;
        public int word_count;
        public boolean has_quiz;
    }

    public static class AsarPage {
        public int id;
        public int page_number;
        public String title;
        public String content;
        public int word_count;
        public List<Quiz> quizzes;
    }

    public static class Quiz {
        public int id;
        public String question;
        public String type;
        public List<String> options;
        public List<Integer> correct_answers;
        public String explanation;
        public int difficulty;
        public int points;
    }
}
