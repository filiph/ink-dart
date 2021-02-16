/// For now, we assume one story. Access to it is provided only through
/// the following functions.
let story;

function inkWrapperLoadStory() {
    story = new inkjs.Story(storyContent);
}

function inkWrapperGlobalTags() {
    return story.globalTags;
}

function inkWrapperStoryCanContinue() {
    return story.canContinue;
}

function inkWrapperStoryContinue() {
    return story.Continue();
}

function inkWrapperStoryCurrentTags() {
    return story.currentTags;
}

function inkWrapperStoryCurrentChoices() {
    return story.currentChoices;
}

function inkWrapperChooseChoiceIndex(index) {
    story.ChooseChoiceIndex(index);
}

function inkWrapperResetState(index) {
    story.ResetState();
}

function inkWrapperVariableStateGet(key) {
    return story.variablesState.$(key);
}

function inkWrapperVariableStateSet(key, value) {
    story.variablesState.$(key, value);
}

