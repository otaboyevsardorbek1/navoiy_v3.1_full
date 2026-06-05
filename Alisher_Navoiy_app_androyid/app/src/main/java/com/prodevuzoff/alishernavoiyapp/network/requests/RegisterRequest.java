package com.prodevuzoff.alishernavoiyapp.network.requests;

public class RegisterRequest {
    public String username;
    public String email;
    public String full_name;
    public String password;

    public RegisterRequest(String username, String email, String full_name, String password) {
        this.username = username;
        this.email = email;
        this.full_name = full_name;
        this.password = password;
    }
}