package com.prodevuzoff.alishernavoiyapp.adapters;

import android.app.AlertDialog;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.drawable.DrawableTransitionOptions;
import com.prodevuzoff.alishernavoiyapp.AsarReaderActivity;
import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.models.ManifestItem;

import java.util.List;

public class AsarlarAdapter extends RecyclerView.Adapter<AsarlarAdapter.AsarViewHolder> {

    private final List<ManifestItem> asarlar;
    private OnAsarActionListener actionListener;

    public interface OnAsarActionListener {
        void onDownloadClick(ManifestItem item, int position);
        void onDeleteClick(ManifestItem item, int position);
    }

    public AsarlarAdapter(List<ManifestItem> asarlar) {
        this.asarlar = asarlar;
    }

    public void setOnAsarActionListener(OnAsarActionListener listener) {
        this.actionListener = listener;
    }

    public void updateData(List<ManifestItem> newAsarlar) {
        this.asarlar.clear();
        this.asarlar.addAll(newAsarlar);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public AsarViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_asar, parent, false);
        return new AsarViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull AsarViewHolder holder, int position) {
        ManifestItem item = asarlar.get(position);
        holder.textViewTitle.setText(item.title_uz);
        holder.textViewPages.setText("Sahifalar: " + item.total_pages);
        holder.textViewVersion.setText("Versiya: " + item.version);

        // Glide orqali muqova rasmini yuklash
        if (item.image_url != null && !item.image_url.isEmpty()) {
            Glide.with(holder.itemView.getContext())
                    .load(item.image_url)
                    .placeholder(R.drawable.ic_launcher_background) // Default rasm
                    .error(R.drawable.ic_launcher_background)
                    .transition(DrawableTransitionOptions.withCrossFade())
                    .into(holder.imageViewCover);
        }

        if (item.is_downloaded || item.is_bundled) {
            holder.buttonDownload.setVisibility(View.GONE);
            holder.imageDownloaded.setVisibility(View.VISIBLE);
            holder.buttonDelete.setVisibility(item.is_bundled ? View.GONE : View.VISIBLE);
            holder.progressBarDownload.setVisibility(View.GONE);
        } else {
            holder.buttonDownload.setVisibility(View.VISIBLE);
            holder.imageDownloaded.setVisibility(View.GONE);
            holder.buttonDelete.setVisibility(View.GONE);
            holder.progressBarDownload.setVisibility(View.GONE);
        }

        holder.buttonDownload.setOnClickListener(v -> {
            if (actionListener != null) {
                holder.buttonDownload.setVisibility(View.GONE);
                holder.progressBarDownload.setVisibility(View.VISIBLE);
                actionListener.onDownloadClick(item, position);
            }
        });

        holder.buttonDelete.setOnClickListener(v -> {
            new AlertDialog.Builder(v.getContext())
                .setTitle("O'chirish")
                .setMessage(item.title_uz + " kitobini qurilmadan o'chirib tashlamoqchimisiz?")
                .setPositiveButton("Ha", (dialog, which) -> {
                    if (actionListener != null) {
                        actionListener.onDeleteClick(item, position);
                    }
                })
                .setNegativeButton("Yo'q", null)
                .show();
        });

        holder.itemView.setOnClickListener(v -> {
            if (item.is_downloaded || item.is_bundled) {
                Intent intent = new Intent(v.getContext(), AsarReaderActivity.class);
                intent.putExtra("asar_slug", item.slug);
                v.getContext().startActivity(intent);
            } else {
                Toast.makeText(v.getContext(), "Avval kitobni yuklab oling", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public int getItemCount() {
        return asarlar.size();
    }

    static class AsarViewHolder extends RecyclerView.ViewHolder {
        TextView textViewTitle, textViewPages, textViewVersion;
        ImageButton buttonDownload, buttonDelete;
        ImageView imageDownloaded, imageViewCover;
        ProgressBar progressBarDownload;

        public AsarViewHolder(@NonNull View itemView) {
            super(itemView);
            textViewTitle = itemView.findViewById(R.id.textViewTitle);
            textViewPages = itemView.findViewById(R.id.textViewPages);
            textViewVersion = itemView.findViewById(R.id.textViewVersion);
            buttonDownload = itemView.findViewById(R.id.buttonDownload);
            buttonDelete = itemView.findViewById(R.id.buttonDelete);
            imageDownloaded = itemView.findViewById(R.id.imageDownloaded);
            imageViewCover = itemView.findViewById(R.id.imageViewCover); // XMLga qo'shildi
            progressBarDownload = itemView.findViewById(R.id.progressBarDownload);
        }
    }
}
