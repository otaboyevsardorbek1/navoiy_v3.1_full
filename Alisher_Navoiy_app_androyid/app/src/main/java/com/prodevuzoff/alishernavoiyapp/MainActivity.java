package com.prodevuzoff.alishernavoiyapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.prodevuzoff.alishernavoiyapp.fragments.AsarlarFragment;
import com.prodevuzoff.alishernavoiyapp.fragments.LeaderboardFragment;
import com.prodevuzoff.alishernavoiyapp.fragments.SettingsFragment;
import com.prodevuzoff.alishernavoiyapp.fragments.SherlarFragment;
import com.prodevuzoff.alishernavoiyapp.fragments.SyncFragment;

public class MainActivity extends AppCompatActivity {

    private Toolbar toolbar;
    private BottomNavigationView bottomNavigationView;
    private TextView textViewConnectivity;
    private ConnectivityManager connectivityManager;
    private ConnectivityManager.NetworkCallback networkCallback;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        applyTheme();
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        textViewConnectivity = findViewById(R.id.textViewConnectivity);
        bottomNavigationView = findViewById(R.id.bottom_navigation);
        
        setupConnectivityMonitoring();

        // Boshlang'ich fragmentni yuklash
        loadFragment(new AsarlarFragment(), "Asarlar");

        bottomNavigationView.setOnItemSelectedListener(item -> {
            Fragment fragment = null;
            String title = "";
            int itemId = item.getItemId();
            
            if (itemId == R.id.nav_asarlar) {
                fragment = new AsarlarFragment();
                title = "Asarlar";
            } else if (itemId == R.id.nav_sherlar) {
                fragment = new SherlarFragment();
                title = "She'rlar";
            } else if (itemId == R.id.nav_leaderboard) {
                fragment = new LeaderboardFragment();
                title = "Reyting";
            } else if (itemId == R.id.nav_sync) {
                fragment = new SyncFragment();
                title = "Sinxronizatsiya";
            } else if (itemId == R.id.nav_settings) {
                fragment = new SettingsFragment();
                title = "Sozlamalar";
            }

            if (fragment != null) {
                loadFragment(fragment, title);
                return true;
            }
            return false;
        });
    }

    private void setupConnectivityMonitoring() {
        connectivityManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        networkCallback = new ConnectivityManager.NetworkCallback() {
            @Override
            public void onAvailable(@NonNull Network network) {
                runOnUiThread(() -> textViewConnectivity.setVisibility(View.GONE));
            }

            @Override
            public void onLost(@NonNull Network network) {
                runOnUiThread(() -> textViewConnectivity.setVisibility(View.VISIBLE));
            }
        };

        NetworkRequest networkRequest = new NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build();
        connectivityManager.registerNetworkCallback(networkRequest, networkCallback);

        // Initial check
        Network activeNetwork = connectivityManager.getActiveNetwork();
        if (activeNetwork == null) {
            textViewConnectivity.setVisibility(View.VISIBLE);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (connectivityManager != null && networkCallback != null) {
            connectivityManager.unregisterNetworkCallback(networkCallback);
        }
    }

    private void loadFragment(Fragment fragment, String title) {
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(title);
        }
    }

    private void applyTheme() {
        SharedPreferences prefs = getSharedPreferences("Settings", Context.MODE_PRIVATE);
        String theme = prefs.getString("app_theme", "classic");
        switch (theme) {
            case "modern":
                setTheme(R.style.Theme_AlisherNavoiyApp_Modern);
                break;
            case "dark":
                setTheme(R.style.Theme_AlisherNavoiyApp_Dark);
                break;
            default:
                setTheme(R.style.Theme_AlisherNavoiyApp_Classic);
                break;
        }
    }
}