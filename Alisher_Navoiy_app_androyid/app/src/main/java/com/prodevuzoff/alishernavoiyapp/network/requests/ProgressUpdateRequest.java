package com.prodevuzoff.alishernavoiyapp.network.requests;

public class ProgressUpdateRequest {
    public int asar_id;
    public int current_page;
    public float scroll_offset;
    public boolean is_completed;

    public ProgressUpdateRequest(int asar_id, int current_page, float scroll_offset, boolean is_completed) {
        this.asar_id = asar_id;
        this.current_page = current_page;
        this.scroll_offset = scroll_offset;
        this.is_completed = is_completed;
    }
}