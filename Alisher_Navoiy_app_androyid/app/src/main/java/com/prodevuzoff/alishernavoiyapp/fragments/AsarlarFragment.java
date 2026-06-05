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
import com.prodevuzoff.alishernavoiyapp.adapters.AsarlarAdapter;
import com.prodevuzoff.alishernavoiyapp.database.AsarManager;
import com.prodevuzoff.alishernavoiyapp.models.Asar;
import com.prodevuzoff.alishernavoiyapp.models.ManifestItem;
import com.prodevuzoff.alishernavoiyapp.network.NetworkClient;
import com.prodevuzoff.alishernavoiyapp.network.responses.SyncManifestResponse;
import com.prodevuzoff.alishernavoiyapp.utils.ErrorUtils;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AsarlarFragment extends Fragment {

    private RecyclerView recyclerView;
    private AsarlarAdapter adapter;
    private SwipeRefreshLayout swipeRefreshLayout;
    private ProgressBar progressBar;
    private AsarManager asarManager;
    private SharedPreferences prefs;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_asarlar, container, false);
        
        asarManager = new AsarManager(requireContext());
        prefs = requireContext().getSharedPreferences("Settings", Context.MODE_PRIVATE);
        
        recyclerView = view.findViewById(R.id.recyclerViewAsarlar);
        swipeRefreshLayout = view.findViewById(R.id.swipeRefreshAsarlar);
        progressBar = view.findViewById(R.id.progressBarAsarlar);

        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new AsarlarAdapter(new ArrayList<>());
        recyclerView.setAdapter(adapter);

        adapter.setOnAsarActionListener(new AsarlarAdapter.OnAsarActionListener() {
            @Override
            public void onDownloadClick(ManifestItem item, int position) {
                downloadAsar(item, position);
            }

            @Override
            public void onDeleteClick(ManifestItem item, int position) {
                deleteAsar(item, position);
            }
        });

        swipeRefreshLayout.setOnRefreshListener(this::loadData);
        
        loadData();
        
        return view;
    }

    private void loadData() {
        boolean isOfflineMode = prefs.getBoolean("offline_mode", false);
        if (isOfflineMode) {
            loadOfflineAsarlar();
            swipeRefreshLayout.setRefreshing(false);
        } else {
            loadAsarlarFromServer();
        }
    }

    private void loadAsarlarFromServer() {
        if (!swipeRefreshLayout.isRefreshing()) {
            progressBar.setVisibility(View.VISIBLE);
        }

        NetworkClient.getApiService(requireContext()).getSyncManifest().enqueue(new Callback<SyncManifestResponse>() {
            @Override
            public void onResponse(Call<SyncManifestResponse> call, Response<SyncManifestResponse> response) {
                if (!isAdded()) return;
                progressBar.setVisibility(View.GONE);
                swipeRefreshLayout.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    List<ManifestItem> items = new ArrayList<>();
                    if (response.body().asarlar != null) {
                        for (SyncManifestResponse.SyncItemMeta meta : response.body().asarlar) {
                            ManifestItem item = new ManifestItem();
                            item.id = meta.id;
                            item.slug = meta.slug;
                            item.version = meta.version;
                            item.checksum = meta.checksum;
                            item.title_uz = meta.slug.replace("-", " ");
                            item.is_downloaded = asarManager.isAsarDownloaded(meta.slug);
                            items.add(item);
                        }
                    }
                    adapter.updateData(items);
                } else {
                    loadOfflineAsarlar();
                }
            }

            @Override
            public void onFailure(Call<SyncManifestResponse> call, Throwable t) {
                if (!isAdded()) return;
                progressBar.setVisibility(View.GONE);
                swipeRefreshLayout.setRefreshing(false);
                loadOfflineAsarlar();
            }
        });
    }

    private void loadOfflineAsarlar() {
        if (!isAdded()) return;
        List<ManifestItem> offlineItems = asarManager.getDownloadedAsarlar();
        if (offlineItems != null) {
            adapter.updateData(offlineItems);
            if (prefs.getBoolean("offline_mode", false)) {
                Toast.makeText(getContext(), "Oflayn rejim (Majburiy)", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(getContext(), "Internet yo'qligi sababli oflayn rejim", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void downloadAsar(ManifestItem item, int position) {
        if (!isAdded()) return;
        if (prefs.getBoolean("offline_mode", false)) {
            Toast.makeText(getContext(), "Oflayn rejimda yuklab bo'lmaydi", Toast.LENGTH_SHORT).show();
            adapter.notifyItemChanged(position);
            return;
        }

        NetworkClient.getApiService(requireContext()).downloadAsar(item.slug).enqueue(new Callback<Asar>() {
            @Override
            public void onResponse(Call<Asar> call, Response<Asar> response) {
                if (!isAdded()) return;
                if (response.isSuccessful() && response.body() != null) {
                    asarManager.saveAsarFull(response.body());
                    item.is_downloaded = true;
                    adapter.notifyItemChanged(position);
                    Toast.makeText(getContext(), "Kitob yuklandi", Toast.LENGTH_SHORT).show();
                } else {
                    adapter.notifyItemChanged(position);
                    ErrorUtils.showResponseError(getContext(), response);
                }
            }

            @Override
            public void onFailure(Call<Asar> call, Throwable t) {
                if (!isAdded()) return;
                adapter.notifyItemChanged(position);
                ErrorUtils.showErrorMessage(getContext(), t);
            }
        });
    }

    private void deleteAsar(ManifestItem item, int position) {
        if (!isAdded()) return;
        asarManager.deleteAsar(item.slug);
        item.is_downloaded = false;
        adapter.notifyItemChanged(position);
        Toast.makeText(getContext(), "Kitob qurilmadan o'chirildi", Toast.LENGTH_SHORT).show();
        
        if (prefs.getBoolean("offline_mode", false)) {
             loadOfflineAsarlar();
        }
    }
}