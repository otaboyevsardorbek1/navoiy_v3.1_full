package com.prodevuzoff.alishernavoiyapp.network.responses;

import java.util.List;

public class LeaderboardResponse {
    public List<UserRank> rankings;

    public static class UserRank {
        public int user_id;
        public String username;
        public String full_name;
        public int total_points;
        public int rank;
    }
}