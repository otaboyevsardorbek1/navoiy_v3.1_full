package com.prodevuzoff.alishernavoiyapp.network.responses;

import java.util.List;

public class QuizSubmitResult {
    public int quiz_id;
    public boolean is_correct;
    public int points_earned;
    public List<Integer> correct_answers;
    public String explanation;
}