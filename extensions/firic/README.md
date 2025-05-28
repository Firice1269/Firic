# Firic
Firic is a custom programming language, with its interpreter being written in Lua.
## Features
Currently, Firic only supports things like variables, if statements, loops, and functions, but will support many more features in the future.
### Comments
Firic does not support block/multiline comments, nor does it support inline comments, but line comments are begun with a double-dash (`--`).

Example:
```swift
foo(bar) --this is a comment
```
### Variables
Firic uses two different keywords for declaring variables: `let` and `var`. Variables declared with the `let` keyword are immutable, while those declared with the `var` keyword are mutable.

Example:
```swift
let x = 24 --immutable
x     = 0  --error

var y = 25 --mutable
y     = 0  --no error
```
### If Statements
In Firic, if statements are first initiated with the `if` keyword, followed by a condition (that must evaluate to a boolean value, otherwise you will get an error). Then, the body of the if statement is enclosed in braces (`{}`). The `elseif` and `else` keywords can be used after that for...well, guess.

Example:
```swift
let n = 81

if n == 80 {
  print("n is 80")
} elseif n == 81 {
  print("n is 81")
} else {
  print("n is not 80 or 81, n is " + n)
}
```
### Loops
Unlike most programming languages, Firic has only one kind of loop (one that runs forever). Loops in Firic are created using the `loop` keyword, with the body (enclosed in braces) immediately following.

Inside loops, the `break` and `continue` keywords can be used to immediately exit the loop, or enter the next iteration of the loop, respectively.

Example:
```swift
--prints every number 1-10
var x = 1

loop {
  print(x)
  x += 1

  if x > 10 {break}
}

--prints every even number 1-10
var x = 1

loop {
  if x % 2 == 1 {continue}

  print(x)
  x += 1

  if x > 10 {break}
}
```
### Functions
Firic functions are called by the function's name, followed by any arguments to be passed to the function, enclosed in parentheses (`()`).

Example:
```swift
foo(bar, baz)
```
#### User-Defined Functions
Functions can be defined by a user with the `func` keyword, followed by the function's name, then its parameters (enclosed in parentheses), and then its body (enclosed in braces).

Example:
```swift
func multiply(a, b) {
  var result = 0

  var counter = a

  loop {
    counter -= 1

    result += b

    if counter == 0 {break}
  }

  return result
}
```
#### Built-In Functions
All functions built into Firic are defined in Lua. The following is the full list of them, each with a description of what they do:

The `print` function takes in a variable number of arguments and prints all of them, separated by newlines.

The `randint` function takes in two arguments (which must both be numbers) and returns a random integer between those two arguments (inclusive).

The `type` function takes in one argument and returns its type as a string.
## Using Firic
Firic does not have a REPL (but it will in the future). Instead, to run any Firic code, you must create a file with the `.fi` file extension, then run the `main.lua` file with the path of the Firic file as a string (the `firic.bat` file does this).
