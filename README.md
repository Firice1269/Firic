# Firic

Firic is a custom programming language, with its interpreter being written in Lua.

## Features

This used to say something else that I forgot about until I noticed it and saw that it was very outdated text.

### Comments

Firic does not support block/multiline comments, nor does it support inline comments, but line comments are begun with a double-dash (`--`).

Example:
```lua
--this is a comment
```

### Data Types

Firic supports 10 basic types: `Array`, `bool` (short for "boolean"), `Dictionary`, `null`, `num` (short for "number"), `str` (short for "string"), `class`, `enum`, `func` (short for "function"), and `module`. In type annotations (see [Type Annotations](#type-annotations) below), there are two extra types: `float` (short for "floating point number") and `int` (short for "integer"). The `num` type encompasses both of these.

#### Type Annotations

In Firic, the type of a variable or function parameter can be annotated by adding a colon (`:`) after the name of the variable/parameter, followed by the name of its type. The type of a function's return type can also be annotated, instead by adding a colon after the parameters of the function, followed by the name of its type. If multiple types are needed in a single type annotation, they can be separated by a vertical bar (`|`). All example code henceforth will use type annotations whenever possible, but note that type annotations are not required. If a type is not annotated, it is inferred.

#### Arrays

Arrays are objects which contain other objects. Arrays can contain any number of values, including none at all, and can contain other arrays. Arrays can be created by enclosing a list of comma-separated values with brackets (`[]`).

To reference a value inside of an array, store the array in a variable (see [Variables](#variables) below) and reference that variable's name, followed by an expression that evaluates to a number (enclosed in brackets). That number is the index of the value to be referenced. Indices start at 0 and increment for each element in the array, but negative indices are also allowed. Negative indices start at the last item in the array (`array[-4]` would be the fourth-to-last element in `array`, and `array[-1]` would be the last).

Example:
```swift
let array: Array[int | Array[int]] = [
	20,
	8,
	9,
	19,
	[9, 19],
	[1, 14],
	[1, 18, 18, 1, 25],
]

print(array[-2]);
```
Output:
```
[
	1,
	14
]
```

#### Booleans

Booleans are values which can be either `true` or `false`.

#### Dictionaries

Dictionaries are objects which contain other objects, like arrays. However, unlike arrays, dictionaries do not store values with ordered numeric indices. Instead, they store values in keys, which can be of any data type (including arrays and dictionaries) and are defined by the user.

To create these key-value pairs, put the key first, then the value, and separate them by a colon. Then, to create a dictionary, simply enclose a list of comma-separated key-value pairs with braces (`{}`). Note that duplicate keys are not permitted.

Referencing a value inside a dictionary is very similar to referencing an element inside an array, only instead of a number, put the key of the key-value pair to be referenced inside the brackets.

Example:
```swift
let dictionary: Dictionary{null | int: str} = {
	null: "",
	0:    "1",
	1:    "0",
}

print(dictionary[1]);
```
Output:
```
0
```

#### Nulls

Null values (`null`) are those which represent the absence of a value. Functions that don't return anything return `null`, as do arrays/dictionaries when you try to reference a value using an index/key that doesn't exist for that object.

#### Strings

Strings are values which represent a body of text, and are always enclosed in quotation marks (`""`). Strings also support the following escape sequences (but more will be added in the future):

`\\`: `\`

`\"`: `"`

`\n`: newline character

Example:
```swift
print("\"Hello, world!\"\n");

print("Escape sequences always begin with a backslash (\\).");
```
Output:
```
"Hello, world!"

Escape sequences always begin with a backslash (\).
```

#### Classes

See [Classes](#classes-1) below.

#### Enums

See [Enums](#enums-2) below.

#### Functions

See [Functions](#functions-1) below.

#### Modules

See [Modules](#modules-1) below.

### Operators

Firic supports the following operators:

#### Unary (Prefix) Operators

`-`: unary subtraction

`~`: bitwise NOT

`!`: logical NOT

#### Binary (Infix) Operators

`**`: exponentiation

`//`: root (a // b = a ** (1 / b))

`*`: multiplication

`/`: division

`%`: modulus

`+`: addition/concatenation

`-`: subtraction

`&`: bitwise AND

`&&`: logical AND

`|`: bitwise OR

`||`: logical OR

`^`: bitwise XOR

`<<`: bitwise left shift

`>>`: bitwise right shift

`=`: assignment

`&=`: bitwise AND assignment

`&&=`: logical AND assignment

`|=`: bitwise OR assignment

`||=`: logical OR assignment

`^=`: bitwise XOR assignment

`<<=`: bitwise left shift assignment

`>>=`: bitwise right shift assignment

`**=`: exponentiation assignment

`//=`: root assignment

`*=`: multiplication assignment

`/=`: division assignment

`%=`: modulus assignment

`+=`: addition/concatenation assignment

`-=`: subtraction assignment

`==`: equal to

`!=`: not equal to

`<`: less than

`<=`: less than/equal to

`>`: greater than

`>=`: greater than/equal to

#### Conditional Operator

The conditional operator (`?:`) takes in three arguments (in other words, it is a ternary operator). If the first argument is `true`, then the expression evaluates to the second argument. Otherwise, it evaluates to the third.

Example:
```swift
print(1 + 1 == 2 ? false : true);
```
Output:
```
false
```

### Variables

Firic uses two different keywords for declaring variables: `let` and `var`. Variables declared with the `let` keyword are immutable, while those declared with the `var` keyword are mutable. If a variable assignment is done on an immutable variable, Firic will throw an error.

Example:
```swift
var x: int = 24
x = 1 

let y: int = -24
y = -1
```
Output:
```
error while evaluating variable assignment at line 5: 'y' is a constant
```

### If Statements

If statements are first initiated with the `if` keyword, followed by a condition (that must evaluate to a boolean value, otherwise Firic will throw an error). Then, the body of the if statement is enclosed in braces. The `elseif` and `else` keywords can be used after that for...well, guess.

Example:
```swift
let n: int = 81

if n == 80 {
	print("n is 80");
} elseif n == 81 {
	print("n is 81");
} else {
	print("n is not 80 or 81, n is " + n);
}
```
Output:
```
n is 81
```

### Switch Statements

Switch statements begin with the `switch` keyword, followed by an expression, then the body (enclosed in braces). The body of a switch statement must consist of at least one case (beginning with the `case` keyword, followed by an expression or set of comma-separated expressions, then a colon, and finally, a body of statements) optionally followed by a default case (beginning with the `default` keyword, followed by a colon, then a body of statements). The switch statement will, for each case, check whether its value is equal to that of the case, and if so, execute the body of the case (if the case has multiple comma-separated values, it will execute as long as at least one of those values match the statement's). If none of a switch statement's cases execute, then, if provided, its default case executes.

Example:
```swift
let text: str = "hey"

switch text {
	case "hello", "hey", "hi":
		print("greetings");
	case "goodbye", "bye":
		print("farewell");
}
```
Output:
```
greetings
```

#### Enums

If an enum case (see [Enums](#enums-2) below) is used as a case's value in a switch statement, and doesn't have a payload (see [Payloads](#payloads) below), then it behaves as normal. However, if the enum case has a payload, then its values can also be extracted from the value provided to the switch statement by setting an identifier for each one in the same order as they are presented in the enum's definition. Each identifier will then be set as a variable for that specific case's execution, with its respective value.

Example:
```swift
enum Vector {
	Vector2(num, num),
	Vector3(num, num, num),
}


let vectors: Array[Vector] = [
	Vector.Vector2(11.66, 8.32),
	Vector.Vector3(4, 56.73, 6.53),
]

for vector in vectors {
	switch vector {
		case Vector.Vector2(x, y):
			print("(" + x + ", " + y + ")");
		case Vector.Vector3(x, y, z):
			print("(" + x + ", " + y + ", " + z + ")");
	}
}
```
Output:
```
(11.66, 8.32)
(4, 56.73, 6.53)
```

### Loops

Firic supports for and while loops.

Inside loops, the `break` and `continue` keywords can be used to immediately exit the loop, or enter the next iteration of the loop, respectively.

#### For Loops

For loops must begin with the `for` keyword, followed by a variable name, then the `in` keyword and an iterator (which must be an array), and finally, the body of the loop (enclosed in braces). The for loop first declares an iterator variable using the variable name after the `for` keyword, setting it equal to the first element in the iterator array, then the second, and so on, until it has looped through every element in the array.

Example:
```swift
let fibonacci: Array[int] = [
	0,
	1,
	1,
	2,
	3,
	5,
	8,
	13,
	21,
	34,
	55,
	89,
	144,
]

for i in fibonacci {
	print("F(" + fibonacci.find(i)[0] + ") = " + i);
}
```
Output:
```
F(0) = 0
F(1) = 1
F(1) = 1
F(3) = 2
F(4) = 3
F(5) = 5
F(6) = 8
F(7) = 13
F(8) = 21
F(9) = 34
F(10) = 55
F(11) = 89
F(12) = 144
```

#### While Loops

While loops must begin with the `while` keyword, followed by a condition. Then, the body of the loop follows (enclosed in braces). The loop will repeatedly execute every statement inside its body until its condition evaluates to `false`.

Example:
```swift
var i: int = 1

while i <= 10 {
	print(i);
	i += 1
}
```
Output:
```
1
2
3
4
5
6
7
8
9
10
```

### Functions

Functions can be called by the function's name, followed by any arguments to be passed to the function, enclosed in parentheses (`()`).

Example:
```swift
foo(bar, baz)
```

#### User-Defined Functions

Functions can be defined by a user with the `func` keyword, followed by the function's name, then its parameters (enclosed in parentheses), and then its body (enclosed in braces). Alternatively, anonymous functions (unnamed function literals) can be created in the exact same way, except for the name of the function being omitted. Additionally, anonymous functions can be assigned to a variable, which can then be reassigned if the function is no longer needed.

Example:
```swift
func multiply(a: num, b: num): num {
	var result: num

	for _ in range(a) {
		result += b
	}

	return result
}

print(multiply(3, 4));
```
Output:
```
12
```

#### Built-In Functions

All functions built into Firic are defined in Lua. The following is the full list of them, each with a description of what they do:

The `print` function takes in a variable number of arguments and prints all of them, separated by newlines.

The `randint` function takes in two arguments (which must both be numbers), the first of which is optional (defaults to `1`), and returns a random integer between those two arguments (inclusive).

The `range` function takes in three arguments (which must all be numbers), the first and last of which are optional (both default to `1`), and returns an array containing every integer between the first and second arguments (inclusive), skipping over any integer that, when subtracted by the first argument, is not divisible by the third argument.

The `require` function takes in one argument (which must be a string) and returns a module from the file that corresponds to that string (searching in the directory that the current file is in, after searching in `modules`). If no file is found, an error is thrown.

The `typeof` function takes in one argument and returns its type as a string.


The `Array.__init` function takes in one argument, attempts to convert the argument to a string, and returns an array containing every character of that string.

The `Array.contains` function takes in one argument and returns `true` if the array contains the argument (or `false` if it doesn't contain the argument).

The `Array.copy` function returns a copy of the array.

The `Array.find` function takes in one argument and returns an array containing every index at which that element occurs in the array.

The `Array.insert` function takes in two arguments (the second of which must be a number), the second of which is optional (defaults to `-1`), inserts the first argument into the array at the index equal to the second argument, and returns the resulting array.

The `Array.length` function returns the length of the array.

The `Array.randelement` function takes in no arguments and returns a random element from the array.

The `Array.remove` function takes in one argument (which must be a number), removes the element at the index equal to it from the array, and returns the resulting array.

The `Array.reverse` function takes in no arguments, reverses the order of the elements in the array, and returns the resulting array.

The `Array.sort` function takes in one argument (which must be a boolean), which is optional (defaults to `false`), sorts the array in ascending order (unless the argument is `true`, in which case the array would be sorted in descending order), and returns the resulting array.


The `bool.__init` function takes in one argument and returns `true` if the argument is `"true"` or a non-zero number, or returns `false` if the argument is `"false"` or `0`.


The `Dictionary.__init` function takes in one argument and, if the argument is an array, for each even index in that array, stores the element at that index as a key inside a dictionary (which is returned when completed), and stores the following element as that key's value.

The `Dictionary.contains` function takes in one argument and returns `true` if the dictionary contains the argument (or `false` otherwise).

The `Dictionary.copy` function returns a copy of the dictionary.

The `Dictionary.find` function takes in one argument and returns an array containing every key at which that value occurs in the dictionary.

The `Dictionary.insert` function takes in two arguments, inserts the first argument into the dictionary with a key equal to the second argument, and returns the resulting dictionary.

The `Dictionary.keys` function takes in no arguments and returns an array containing all of the keys of the dictionary.

The `Dictionary.length` function returns the length of the dictionary.

The `Dictionary.remove` function takes in one argument, removes the value at the key equal to it from the dictionary, and returns the resulting dictionary.

The `Dictionary.values` function takes in no arguments and returns an array containing all of the values of the dictionary.


The `num.__init` function takes in one argument and returns `1` if the argument is `true`, `0` if the argument is `false`, or a number from a string if the string is able to be parsed as a number.


The `str.capitalize` function takes in no arguments, makes the first character of each substring (separated by spaces) in the string an uppercase letter (if possible), and returns the resulting string.

The `str.copy` function returns a copy of the string.

The `str.decapitalize` function takes in no arguments, makes the first character of the string a lowercase letter (if possible), and returns the resulting string.

The `str.endswith` function takes in one argument and returns `true` if the string's last character is equal to the argument (or `false` otherwise).

The `str.length` function returns the length of the string.

The `str.lower` function takes in no arguments, makes all characters of the string uppercase letters (if possible), and returns the resulting string.

The `str.upper` function takes in no arguments, makes all characters of the string lowercase letters (if possible), and returns the resulting string.

The `str.startswith` function takes in one argument and returns `true` if the string's first character is equal to the argument (or `false` otherwise).

### Classes

Classes can be defined by the `class` keyword, followed by the class's name, then its body (enclosed in braces). Any variables declared inside the body can be used as properties, and any functions defined inside the body can be used as methods. A class's traits can all be referenced by using dot notation. Note that the first parameter of any class method is reserved for the current class instance. Any example Firic code with classes will always call this parameter `self`, but it can have any name.

Example:
```swift
class Person {
	var name: str

	func __init(self, name) {
		self.name = name.lower().capitalize()
	}


	func greet(self, person: Person): null {
		print(self.name + " says \"Hello, " + person.name +".\"");
	}
}

let foo: Person = Person("foo")
let bar: Person = Person("bar")
foo.greet(bar);
```
Output:
```
Foo says "Hello, Bar."
```

#### Inheritance

Classes can inherit traits from other classes. To do this, define a class, but place a colon followed by another class's name before the body. This will allow the class being defined to use all methods and properties from the inherited class.

Example:
```swift
class Animal {
	var type: str
	var name: str
}


class Cat: Animal {
	type = "Feline"

	func __init(self, name): null {
		self.name = name.lower().capitalize()
	}
}

class Dog: Animal {
	type = "Canine"

	func __init(self, name): null {
		self.name = name.lower().capitalize()
	}
}


let cat: Cat = Cat("tacocat")
let dog: Dog = Dog("dog god")

print(cat.name, cat.type);
print();
print(dog.name, dog.type);
```
Output:
```
Tacocat
Feline

Dog God
Canine
```

#### Magic Methods

Magic methods are those which have an additional use to whatever functionality the user gives them. Firic currently supports the following magic methods:

`__init`: initializer

`__str`: tostring converter

### Enums

Enums can be defined using the `enum` keyword, followed by the enum's name, then its body (enclosed in braces). An enum's body should contain a list of comma-separated values, like an array, except these values are called cases, and can be referenced like class traits (using dot notation).

Example:
```swift
enum AnimalType {
	Feline,
	Canine,
}



class Animal {
	var type: AnimalType
	var name: str
}


class Cat: Animal {
	type = AnimalType.Feline

	func __init(self, name): null {
		self.name = name.lower().capitalize()
	}
}

class Dog: Animal {
	type = AnimalType.Canine

	func __init(self, name): null {
		self.name = name.lower().capitalize()
	}
}


let cat: Cat = Cat("tacocat")
let dog: Dog = Dog("dog god")

print(cat.name, cat.type);
print();
print(dog.name, dog.type);
```
Output:
```
Tacocat
Feline

Dog God
Canine
```

#### Payloads

Any given enum case can have a payload, or set of associated values to go with it. To add a payload to a case, place a set of comma-separated type annotations (without the colon) inside parentheses following the case's name. These indicate which types their respective values can be set to. When a case that has a payload is used, all of its payload's values must be included in a comma-separated list (enclosed in parentheses).

Example:
```swift
enum Vector {
	Vector2(num, num),
	Vector3(num, num, num),
}


let circlePosition: Vector = Vector.Vector2(11.66, 8.32)
let spherePosition: Vector = Vector.Vector3(4, 56.73, 6.53)
print(circlePosition, spherePosition);
```
Output:
```
Vector.Vector2(11.66, 8.32)
Vector.Vector3(4, 56.73, 6.53)
```

### Modules

Modules are returned by the `require` function, and can contain any number of variables, which can be referenced using dot notation. Note that modules can only contain exported variables, which are those whose definitions are preceded by the `export` keyword.

Example:

`module.fi`:
```typescript
export let pi: float = 3.14159


export func sayHello(): null {
	print("Hello, world!");
}
```
`main.fi`:
```swift
let module: module = require("module")

module.sayHello();
print(module.pi);
```
Output:
```
Hello, world!
3.14159
```

## Using Firic

There are two main ways to run Firic. One is to create a file with the `.fi` file extension, then run the `main.lua` file with the path of the Firic file (the `firic.bat` (Windows) and `firic.sh` (Linux) files do this). The other is to run the `main.lua` file with no arguments, which will open a REPL.
