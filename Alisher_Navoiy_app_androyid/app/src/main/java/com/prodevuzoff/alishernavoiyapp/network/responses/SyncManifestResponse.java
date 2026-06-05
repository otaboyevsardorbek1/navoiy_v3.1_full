package com.prodevuzoff.alishernavoiyapp.network.responses;

import java.util.List;

public class SyncManifestResponse {
    public int bundle_version;
    public String generated_at;
    public List<SyncItemMeta> asarlar;
    public List<SyncItemMeta> sherlar;
    public int total_items;

    public static class SyncItemMeta {
        public int id;
        public String slug;
        public String content_type;
        public int version;
        public String checksum;
        public long file_size_bytes;
        public String updated_at;
    }
}