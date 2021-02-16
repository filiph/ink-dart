@JS()
library stringify;

import 'package:js/js.dart';

external void inkWrapperLoadStory();

external List<String> inkWrapperGlobalTags();

external bool inkWrapperStoryCanContinue();

external String inkWrapperStoryContinue();

external List<String> inkWrapperStoryCurrentTags();

external List<InkWrapperChoice> inkWrapperStoryCurrentChoices();

external void inkWrapperChooseChoiceIndex(int index);

external void inkWrapperResetState();

external dynamic inkWrapperVariableStateGet(String key);

external void inkWrapperVariableStateSet(String key, dynamic value);

@JS()
class InkWrapperChoice {
  external String get text;
  external int get index;
}
