package com.prodevuzoff.alishernavoiyapp.network.responses;

import com.google.gson.annotations.SerializedName;

public class AppConfigResponse {
    @SerializedName("min_version")
    public int minVersion;
    
    @SerializedName("latest_version")
    public int latestVersion;
    
    @SerializedName("force_update")
    public boolean forceUpdate;
    
    @SerializedName("maintenance_mode")
    public boolean maintenanceMode;
    
    @SerializedName("update_url")
    public String updateUrl;
    
    @SerializedName("security_hash")
    public String securityHash; // X-App-Signature tekshirish uchun
}