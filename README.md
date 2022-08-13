Lox implemented in Dart
=======================

A Dart port of Bob Nystrom **Lox** interpreter from his book **[Crafting Interpreters](https://www.craftinginterpreters.com/)**.

When Bob started his book, Java might have been a good choice but time flies and because Bob is working on Dart, it was fun to port all the Java code to [Dart](https://dart.dev).

I made roughly one commit per chapter, so in theory you can follow along by checking out the code commit by commit. I tried to stay as close as possible to the [Java source](https://github.com/munificent/craftinginterpreters) even if this means that the result isn't ideomatic. Still, the result is a bit shorter and IMHO more distinct.

Have fun.

## Note

I converted this project to [null safety](https://dart.dev/null-safety), so it requires Dart 2.12 or better. Run the application with `dart bin/main.dart`.