package com.prodevuzoff.alishernavoiyapp.fragments;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.prodevuzoff.alishernavoiyapp.LoginActivity;
import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.responses.UserStatsResponse;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProfileFragment extends Fragment {

    private TextView textViewFullName, textViewUsername;
    private TextView valTotalRead, valTotalPoints, valQuizzes, valFavorites;
    private Button buttonLogout;
    private ProgressBar progressBar;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_profile, container, false);

        textViewFullName = view.findViewById(R.id.textViewFullName);
        textViewUsername = view.findViewById(R.id.textViewUsername);
        valTotalRead = view.findViewById(R.id.valTotalRead);
        valTotalPoints = view.findViewById(R.id.valTotalPoints);
        valQuizzes = view.findViewById(R.id.valQuizzes);
        valFavorites = view.findViewById(R.id.valFavorites);
        buttonLogout = view.findViewById(R.id.buttonLogout);
        progressBar = view.findViewById(R.id.progressBarProfile);

        loadUserDataFromPrefs();
        loadUserStatsFromServer();

        buttonLogout.setOnClickListener(v -> logout());

        return view;
    }

    private void loadUserDataFromPrefs() {
        SharedPreferences authPrefs = requireContext().getSharedPreferences("Auth", Context.MODE_PRIVATE);
        String username = authPrefs.getString("username", "Foydalanuvchi");
        String fullName = authPrefs.getString("full_name", username);
        
        textViewUsername.setText("@" + username);
        textViewFullName.setText(fullName);
    }

    private void loadUserStatsFromServer() {
        if (progressBar != null) progressBar.setVisibility(View.VISIBLE);

        NetworkClient.getApiService(requireContext()).getUserStats().enqueue(new Callback<UserStatsResponse>() {
            @Override
            public void onResponse(Call<UserStatsResponse> call, Response<UserStatsResponse> response) {
                if (progressBar != null) progressBar.setVisibility(View.GONE);
                if (response.isSuccessful() && response.body() != null) {
                    UserStatsResponse stats = response.body();
                    valTotalRead.setText(String.valueOf(stats.total_read));
                    valTotalPoints.setText(String.valueOf(stats.total_points));
                    valQuizzes.setText(String.valueOf(stats.total_quiz_answered));
                    valFavorites.setText(String.valueOf(stats.favorite_count));
                } else {
                    // Don't show error toast if it's just a connection issue in offline mode
                    if (progressBar != null) progressBar.setVisibility(View.GONE);
                }
            }

            @Override
            public void onFailure(Call<UserStatsResponse> call, Throwable t) {
                if (progressBar != null) progressBar.setVisibility(View.GONE);
                // Silent failure in profile stats is better for UX when offline
            }
        });
    }

    private void logout() {
        // Clear all session data
        SharedPreferences authPrefs = requireContext().getSharedPreferences("Auth", Context.MODE_PRIVATE);
        authPrefs.edit().clear().apply();
        
        SharedPreferences settingsPrefs = requireContext().getSharedPreferences("Settings", Context.MODE_PRIVATE);
        settingsPrefs.edit().putBoolean("is_logged_in", false).apply();

        // Navigate to Login and clear backstack
        Intent intent = new Intent(getActivity(), LoginActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        if (getActivity() != null) {
            getActivity().finish();
        }
    }
}
