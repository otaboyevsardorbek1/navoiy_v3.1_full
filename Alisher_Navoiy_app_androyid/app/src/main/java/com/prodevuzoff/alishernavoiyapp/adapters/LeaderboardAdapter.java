package com.prodevuzoff.alishernavoiyapp.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.prodevuzoff.alishernavoiyapp.R;
import com.prodevuzoff.alishernavoiyapp.network.responses.LeaderboardResponse;
import java.util.List;

public class LeaderboardAdapter extends RecyclerView.Adapter<LeaderboardAdapter.LeaderboardViewHolder> {

    private List<LeaderboardResponse.UserRank> rankings;

    public LeaderboardAdapter(List<LeaderboardResponse.UserRank> rankings) {
        this.rankings = rankings;
    }

    public void setRankings(List<LeaderboardResponse.UserRank> rankings) {
        this.rankings = rankings;
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public LeaderboardViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_leaderboard, parent, false);
        return new LeaderboardViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull LeaderboardViewHolder holder, int position) {
        LeaderboardResponse.UserRank rank = rankings.get(position);
        holder.textViewRank.setText(String.valueOf(rank.rank));
        holder.textViewUserName.setText(rank.full_name);
        holder.textViewUserLogin.setText("@" + rank.username);
        holder.textViewPoints.setText(rank.total_points + " ball");
        
        // Highlight top 3
        if (rank.rank == 1) holder.textViewRank.setTextColor(0xFFFFD700); // Gold
        else if (rank.rank == 2) holder.textViewRank.setTextColor(0xFFC0C0C0); // Silver
        else if (rank.rank == 3) holder.textViewRank.setTextColor(0xFFCD7F32); // Bronze
        else holder.textViewRank.setTextColor(0xFF000000);
    }

    @Override
    public int getItemCount() {
        return rankings != null ? rankings.size() : 0;
    }

    static class LeaderboardViewHolder extends RecyclerView.ViewHolder {
        TextView textViewRank, textViewUserName, textViewUserLogin, textViewPoints;

        public LeaderboardViewHolder(@NonNull View itemView) {
            super(itemView);
            textViewRank = itemView.findViewById(R.id.textViewRank);
            textViewUserName = itemView.findViewById(R.id.textViewUserName);
            textViewUserLogin = itemView.findViewById(R.id.textViewUserLogin);
            textViewPoints = itemView.findViewById(R.id.textViewPoints);
        }
    }
}