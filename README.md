Lox implemented in Dart
=======================

A Dart port of Bob Nystrom **Lox** interpreter from his book **[Crafting Interpreters](https://www.craftinginterpreters.com/)**.

When Bob started his book, Java might have been a good choice but time flies and because Bob is working on Dart, it was fun to port all the Java code to [Dart](https://dart.dev).

I made roughly one commit per chapter, so in theory you can follow along by checking out the code commit by commit. I tried to stay as close as possible to the [Java source](https://github.com/munificent/craftinginterpreters) even if this means that the result isn't ideomatic. Still, the result is a bit shorter and IMHO more distinct.

Have fun.

## Note

To recreate `ast.dart`, `expr.dart`, and `stmt.dart`, run

    dart run bin/generate_ast.dart lib

To launch the Lox REPL, run

    dart run bin/main.dart

To run the example `*.lox` files, run

    for i in *.lox; do dart run bin/main.dart $i; done
