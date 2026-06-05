package com.prodevuzoff.alishernavoiyapp.network.responses;

import com.prodevuzoff.alishernavoiyapp.models.User;

public class TokenResponse {
    public String access_token;
    public String refresh_token;
    public String token_type;
    public int expires_in;
    public User user;
}
