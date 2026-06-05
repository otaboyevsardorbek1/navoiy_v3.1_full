package com.prodevuzoff.alishernavoiyapp.models;

public class ManifestItem {
    public int id;
    public String slug;
    public String title_uz;
    public String image_url;
    public int total_pages;
    public int version;
    public boolean is_bundled;
    public String checksum;
    public boolean is_downloaded; // New field for UI state
}