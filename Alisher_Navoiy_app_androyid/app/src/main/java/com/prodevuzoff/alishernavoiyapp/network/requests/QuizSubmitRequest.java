package com.prodevuzoff.alishernavoiyapp.network.requests;

import java.util.List;

public class QuizSubmitRequest {
    public int quiz_id;
    public List<Integer> selected_answers;
    public int time_spent_seconds;

    public QuizSubmitRequest(int quiz_id, List<Integer> selected_answers, int time_spent_seconds) {
        this.quiz_id = quiz_id;
        this.selected_answers = selected_answers;
        this.time_spent_seconds = time_spent_seconds;
    }
}