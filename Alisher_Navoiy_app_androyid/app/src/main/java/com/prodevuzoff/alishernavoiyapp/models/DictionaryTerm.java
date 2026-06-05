package com.prodevuzoff.alishernavoiyapp.models;

public class DictionaryTerm {
    public int id;
    public String term;
    public String definition;
    public String category;

    public DictionaryTerm() {}

    public DictionaryTerm(String term, String definition, String category) {
        this.term = term;
        this.definition = definition;
        this.category = category;
    }
}
