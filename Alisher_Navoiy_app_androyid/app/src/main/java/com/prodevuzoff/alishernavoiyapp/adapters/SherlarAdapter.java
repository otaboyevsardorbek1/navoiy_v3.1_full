package com.prodevuzoff.alishernavoiyapp.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.models.Sher;
import java.util.List;

public class SherlarAdapter extends RecyclerView.Adapter<SherlarAdapter.SherViewHolder> {

    private final List<Sher> sherlar;

    public SherlarAdapter(List<Sher> sherlar) {
        this.sherlar = sherlar;
    }

    public void updateData(List<Sher> newSherlar) {
        this.sherlar.clear();
        this.sherlar.addAll(newSherlar);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public SherViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_sher, parent, false);
        return new SherViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull SherViewHolder holder, int position) {
        Sher sher = sherlar.get(position);
        holder.textViewTitle.setText(sher.title);
        holder.textViewType.setText(sher.type);
        holder.textViewContent.setText(sher.content);
    }

    @Override
    public int getItemCount() {
        return sherlar.size();
    }

    static class SherViewHolder extends RecyclerView.ViewHolder {
        TextView textViewTitle, textViewType, textViewContent;

        public SherViewHolder(@NonNull View itemView) {
            super(itemView);
            textViewTitle = itemView.findViewById(R.id.textViewSherTitle);
            textViewType = itemView.findViewById(R.id.textViewSherType);
            textViewContent = itemView.findViewById(R.id.textViewSherContent);
        }
    }
}