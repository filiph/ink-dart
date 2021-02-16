import 'dart:async';
import 'dart:html';

import 'package:async/async.dart';
import 'package:ink_dart/ink_dart.dart';

// ignore_for_file: avoid_print

Future<void> main() async {
  final output = querySelector('#story') as DivElement;
  final choicesElement = querySelector('#choices') as DivElement;
  final outerScrollContainer = querySelector('.outerContainer') as DivElement;
  final pressSpacePromptElement =
      querySelector('#press-space-prompt') as DivElement;

  final webGame = WebGame(window, output, choicesElement, outerScrollContainer,
      pressSpacePromptElement);
  await webGame.play();
  webGame.close();
}

class WebGame {
  static final RegExp _sentence = RegExp(r'.+?[\.!?$]+["]?\s*');

  final Story story;

  final Window window;

  final DivElement output;

  final DivElement choicesElement;

  final DivElement outerScrollContainer;

  final DivElement pressSpacePromptElement;

  late final StreamSubscription _keyPressSubscription;

  /// On mobile, "space key press" is replaced with tapping.
  late final StreamSubscription _keyPressTapSubscription;

  late final _keyPressController = StreamController<void>();

  late final StreamQueue<void> _keyPress =
      StreamQueue(_keyPressController.stream);

  WebGame(
    this.window,
    this.output,
    this.choicesElement,
    this.outerScrollContainer,
    this.pressSpacePromptElement,
  ) : story = Story() {
    _keyPressSubscription = window.onKeyPress.listen((event) {
      if (event.keyCode == 32 && _takingSpacePresses) {
        // Space
        _keyPressController.add(null);
        event.preventDefault();
      }
    });

    _keyPressTapSubscription = window.onClick.listen((event) {
      if (_takingSpacePresses) {
        _keyPressController.add(null);
        event.preventDefault();
      }
    });
  }

  void close() {
    _keyPressTapSubscription.cancel();
    _keyPressSubscription.cancel();
    _keyPress.cancel();
    _keyPressController.close();
  }

  Future<void> play() async {
    // ignore: literal_only_boolean_expressions
    while (true) {
      // Print out all paragraphs.
      while (story.canContinue) {
        _previousBottomEdge = _contentBottomEdgeY;

        final paragraphText = story.continueStory();
        _showPressSpacePrompt(true);
        await _showParagraph(paragraphText);

        await _keyPress.next;

        _updateOutputHeight();
        await _scrollDown(_previousBottomEdge);
      }
      _showPressSpacePrompt(false);

      assert(story.currentChoices.isNotEmpty);
      final choiceTaken = Completer<int>();
      final paragraphs = <ParagraphElement>[];
      final subscriptions = <StreamSubscription>[];

      for (final choice in story.currentChoices) {
        final choiceParagraph = ParagraphElement()
          ..children.add(Element.a()
            ..text = choice.text
            ..attributes['href'] = '#')
          ..classes.add('choice');
        subscriptions.add(choiceParagraph.onClick.listen((event) {
          choiceTaken.complete(choice.index);
          event.preventDefault();
          event.stopPropagation();
        }));
        paragraphs.add(choiceParagraph);
        choicesElement.children.add(choiceParagraph);
      }
      _updateOutputHeight();

      await _scrollDown(_previousBottomEdge);

      final index = await choiceTaken.future;
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      for (final paragraph in paragraphs) {
        paragraph.remove();
      }
      story.chooseIndex(index);

      // Also show the first paragraph of the response.
      _keyPressController.add(null);
    }
  }

  bool _takingSpacePresses = true;

  /// Extend height to fit
  /// We do this manually so that removing elements and creating new ones
  /// doesn't cause the height (and therefore scroll) to jump backwards
  /// temporarily.
  /// (Taken from the inkjs runner.)
  void _updateOutputHeight() {
    output.style.height = '${_contentBottomEdgeY}px';
  }

  // The Y coordinate of the bottom end of all the story content, used
  // for growing the container, and deciding how far to scroll.
  // (Taken from the inkjs runner.)
  int get _contentBottomEdgeY {
    if (output.children.isEmpty) return 0;
    var bottomElement = output.children.last;
    final result = bottomElement.offsetTop + bottomElement.offsetHeight;
    return result;
  }

  void _showPressSpacePrompt(bool value) {
    if (value) {
      pressSpacePromptElement.classes.remove('hidden');
    } else {
      pressSpacePromptElement.classes.add('hidden');
    }
    _takingSpacePresses = value;
  }

  /// The previous span that was added. Used to dim text before the current
  /// sentence.
  SpanElement? _previousSentenceSpan;

  Future<void> _showParagraph(String text) async {
    assert(!text.contains('<'), 'Not ready for HTML in text: "$text"');

    final paragraph = ParagraphElement();
    output.children.add(paragraph);

    final sentences = _sentence.allMatches(text);

    var first = true;
    for (final sentence in sentences) {
      if (!first) {
        await _keyPress.next;
      }
      final span = SpanElement()..text = sentence.group(0);
      // Start hidden.
      span.classes.add('hide');
      paragraph.children.add(span);
      first = false;

      if (_previousSentenceSpan != null) {
        _previousSentenceSpan!.classes.add('dimmed');
      }
      _previousSentenceSpan = span;
      await window.animationFrame;
      span.classes.remove('hide');
    }
  }

  int _previousBottomEdge = 0;

  // Scrolls the page down, but no further than the bottom edge of what
  // you could see previously, so it doesn't go too far.
  // (Taken from the inkjs runner.)
  Future<void> _scrollDown(int previousBottomEdge) async {
    // Line up top of screen with the bottom of where the previous content ended
    var target = previousBottomEdge;

    // Can't go further than the very bottom of the page
    var limit =
        outerScrollContainer.scrollHeight - outerScrollContainer.clientHeight;
    if (target > limit) target = limit;

    var start = outerScrollContainer.scrollTop;

    final completer = Completer<void>();
    var dist = target - start;
    var duration = 300 + 300 * dist / 100;
    num? startTime;
    void step(num time) {
      startTime ??= time;
      var t = (time - startTime!) / duration;
      var lerp = 3 * t * t - 2 * t * t * t; // ease in/out
      outerScrollContainer.scrollTo(0, (1.0 - lerp) * start + lerp * target);
      if (t < 1) {
        window.requestAnimationFrame(step);
      } else {
        completer.complete();
      }
    }

    window.requestAnimationFrame(step);
    await completer.future;
  }
}
