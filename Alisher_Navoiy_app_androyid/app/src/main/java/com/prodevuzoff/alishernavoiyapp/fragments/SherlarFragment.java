package com.prodevuzoff.alishernavoiyapp.fragments;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.adapters.SherlarAdapter;
import com.prodevuzoff.alishernavoiyapp.database.SherManager;
import com.prodevuzoff.alishernavoiyapp.models.Sher;
import com.prodevuzoff.alishernavoiyapp.network.ApiService;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SherlarFragment extends Fragment {

    private RecyclerView recyclerView;
    private SherlarAdapter adapter;
    private SwipeRefreshLayout swipeRefreshLayout;
    private ProgressBar progressBar;
    private SherManager sherManager;
    private SharedPreferences prefs;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_sherlar, container, false);
        
        sherManager = new SherManager(requireContext());
        prefs = requireContext().getSharedPreferences("Settings", Context.MODE_PRIVATE);
        
        recyclerView = view.findViewById(R.id.recyclerViewSherlar);
        swipeRefreshLayout = view.findViewById(R.id.swipeRefreshSherlar);
        progressBar = view.findViewById(R.id.progressBarSherlar);

        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new SherlarAdapter(new ArrayList<>());
        recyclerView.setAdapter(adapter);

        swipeRefreshLayout.setOnRefreshListener(this::loadData);
        
        loadData();
        
        return view;
    }

    private void loadData() {
        boolean isOfflineMode = prefs.getBoolean("offline_mode", false);
        if (isOfflineMode) {
            loadOfflineSherlar();
            swipeRefreshLayout.setRefreshing(false);
        } else {
            loadSherlarFromServer();
        }
    }

    private void loadSherlarFromServer() {
        if (!swipeRefreshLayout.isRefreshing()) {
            progressBar.setVisibility(View.VISIBLE);
        }

        NetworkClient.getApiService(requireContext()).getSherlar(1, 100).enqueue(new Callback<ApiService.PaginatedResponse<Sher>>() {
            @Override
            public void onResponse(Call<ApiService.PaginatedResponse<Sher>> call, Response<ApiService.PaginatedResponse<Sher>> response) {
                if (!isAdded()) return;
                progressBar.setVisibility(View.GONE);
                swipeRefreshLayout.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    List<Sher> sherlar = response.body().items;
                    if (sherlar != null) {
                        sherManager.saveSherlar(sherlar);
                        adapter.updateData(sherlar);
                    }
                } else {
                    loadOfflineSherlar();
                    ErrorUtils.showResponseError(getContext(), response);
                }
            }

            @Override
            public void onFailure(Call<ApiService.PaginatedResponse<Sher>> call, Throwable t) {
                if (!isAdded()) return;
                progressBar.setVisibility(View.GONE);
                swipeRefreshLayout.setRefreshing(false);
                loadOfflineSherlar();
                // Faqat oflayn rejim majburiy bo'lmasa xatoni ko'rsatamiz
                if (!prefs.getBoolean("offline_mode", false)) {
                    ErrorUtils.showErrorMessage(getContext(), t);
                }
            }
        });
    }

    private void loadOfflineSherlar() {
        if (!isAdded()) return;
        List<Sher> offlineSherlar = sherManager.getAllSherlar();
        if (offlineSherlar != null && !offlineSherlar.isEmpty()) {
            adapter.updateData(offlineSherlar);
        }
    }
}