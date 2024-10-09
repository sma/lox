#!/bin/bash

actual=""
for i in *.lox; do
    actual+="---- $(echo $i) ----\n"
    output=$(dart run bin/lox.dart $i)
    actual+="$output\n"
done

expected="\
---- class1.lox ----
Bagel instance
---- class2.lox ----
3
---- class3.lox ----
Crunch crunch crunch!
---- class4.lox ----
C instance
---- class5.lox ----
bar
---- closure.lox ----
1
2
---- fib.lox ----
0
1
1
2
3
5
8
13
21
34
55
89
144
233
377
610
987
1597
2584
4181
---- for.lox ----
0
1
2
3
4
---
1
2
3
4
5
---- functions.lox ----
<fn add>
7
1
2
3
Hi, Dear Reader!
---- scope.lox ----
inner a
outer b
global c
outer a
outer b
global c
global a
global b
global c
---- superclass1.lox ----
Fry until golden brown.
---- superclass2.lox ----
Fry until golden brown.
Pipe full of custard and coat with chocolate.
---- while.lox ----
10
"
diff <(echo -e "$actual") <(echo -e "$expected") && echo "OK"
