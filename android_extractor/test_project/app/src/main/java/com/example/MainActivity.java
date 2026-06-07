package com.example;

import android.app.Activity;
import android.os.Bundle;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // TODO: Implement main functionality
        try {
            initApp();
        } catch (Exception e) {
            // Empty catch - bad practice
        }
    }

    private void initApp() {
        // Application initialization
    }
}
