/// Support for embedding Ink stories in Dart on the web.
library ink_dart;

import 'dart:collection';

import 'package:ink_dart/src/ink_dart_base.dart';

import 'src/ink_dart_base.dart';

class Choice {
  final String text;

  final int index;

  const Choice(this.index, this.text);

  @override
  String toString() => 'Choice<$index, $text>';
}

class Story {
  late final List<String> _globalTags;

  late final _VariableState variableState;

  Story() {
    inkWrapperLoadStory();
    _globalTags = inkWrapperGlobalTags().cast<String>();
    variableState = _VariableState(this);
  }

  bool get canContinue => inkWrapperStoryCanContinue();

  List<Choice> get currentChoices =>
      List.unmodifiable(inkWrapperStoryCurrentChoices()
          .cast<InkWrapperChoice>()
          .map<Choice>((c) => Choice(c.index, c.text)));

  UnmodifiableListView<String> get currentTags =>
      UnmodifiableListView(inkWrapperStoryCurrentTags().cast<String>());

  UnmodifiableListView<String> get globalTags =>
      UnmodifiableListView(_globalTags);

  void chooseIndex(int index) {
    inkWrapperChooseChoiceIndex(index);
  }

  String continueStory() => inkWrapperStoryContinue();

  void resetState() {
    inkWrapperResetState();
  }

  dynamic _variableStateGet(String key) {
    return inkWrapperVariableStateGet(key);
  }

  dynamic _variableStateSet(String key, dynamic value) {
    return inkWrapperVariableStateSet(key, value);
  }
}

class _VariableState {
  final Story _story;

  const _VariableState(this._story);

  dynamic operator [](String key) => _story._variableStateGet(key);

  void operator []=(String key, dynamic value) =>
      _story._variableStateSet(key, value);
}
