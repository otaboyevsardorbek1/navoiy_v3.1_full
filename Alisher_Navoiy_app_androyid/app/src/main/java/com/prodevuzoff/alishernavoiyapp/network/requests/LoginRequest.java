package com.prodevuzoff.alishernavoiyapp.network.requests;

public class LoginRequest {
    public String username;
    public String password;
    public String device_info;

    public LoginRequest(String username, String password, String device_info) {
        this.username = username;
        this.password = password;
        this.device_info = device_info;
    }
}