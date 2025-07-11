# Firic

Firic is a custom programming language, with its interpreter being written in Lua.

## Features

Currently, Firic only supports things like variables, if statements, loops, and functions, but will support many more features in the future.

### Comments

Firic does not support block/multiline comments, nor does it support inline comments, but line comments are begun with a double-dash (`--`).

Example:
```lua
--this is a comment
```

### Data Types

Firic supports 10 basic types: `array`, `bool` (short for "boolean"), `case`, `class`, `dict` (short for "dictionary"), `enum` `null`, `num` (short for "number"), `str` (short for "string"), and `func` (short for "function").

#### Arrays

Arrays are objects which contain other objects. Arrays can contain any number of values, including none at all, and can contain other arrays. Arrays can be created by enclosing a list of comma-separated values with brackets (`[]`).

To reference a value inside of an array, store the array in a variable (see [Variables](#variables) below) and reference that variable's name, followed by an expression that evaluates to a number (enclosed in brackets). That number is the index of the value to be referenced. Indices start at 0 and increment for each element in the array, but negative indices are also allowed. Negative indices start at the last item in the array (`array[-4]` would be the fourth-to-last element in `array`, and `array[-1]` would be the last).

Example:
```swift
let array = [
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
```lua
[
	1,
	14
]
```

#### Booleans

Booleans are values which can be either `true` or `false`.

#### Cases

See [Enums](#enums-1) below.

#### Classes

See [Classes](#classes-1) below.

#### Dictionaries

Dictionaries are objects which contain other objects, like arrays. However, unlike arrays, dictionaries do not store values with ordered numeric indices. Instead, they store values in keys, which can be of any data type (including arrays and dictionaries) and are defined by the user.

To create these key-value pairs, put the key first, then the value, and separate them by a colon (`:`). Then, to create a dictionary, simply enclose a list of comma-separated key-value pairs with braces (`{}`). Note that duplicate keys are not permitted.

Referencing a value inside a dictionary is very similar to referencing an element inside an array, only instead of a number, put the key of the key-value pair to be referenced inside the brackets.

Example:
```swift
let dict = {
	null: "",
	0:    "1",
	1:    "0",
}

print(dict[1]);
```
Output:
```
0
```

#### Enums

See [Enums](#enums-1) below.

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

#### Functions

See [Functions](#functions-1) below.

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
```lua
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
var x = 24
x     = 1 

let y = -24
y     = -1
```
Output:
```
error while evaluating variable assignment at line 5: 'y' is a constant
```

### If Statements

If statements are first initiated with the `if` keyword, followed by a condition (that must evaluate to a boolean value, otherwise Firic will throw an error). Then, the body of the if statement is enclosed in braces. The `elseif` and `else` keywords can be used after that for...well, guess.

Example:
```swift
let n = 81

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

### Loops

Firic supports for and while loops.

Inside loops, the `break` and `continue` keywords can be used to immediately exit the loop, or enter the next iteration of the loop, respectively.

#### For Loops

For loops must begin with the `for` keyword, followed by a variable name, then the `in` keyword and an iterator (which must be an array), and finally, the body of the loop (enclosed in braces). The for loop first declares an iterator variable using the variable name after the `for` keyword, setting it equal to the first element in the iterator array, then the second, and so on, until it has looped through every element in the array.

Example:
```swift
let fibonacci = [
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
var i = 1

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
```lua
foo(bar, baz)
```

#### User-Defined Functions

Functions can be defined by a user with the `func` keyword, followed by the function's name, then its parameters (enclosed in parentheses), and then its body (enclosed in braces). Alternatively, anonymous functions (unnamed function literals) can be created in the exact same way, except for the name of the function being omitted. Additionally, anonymous functions can be assigned to a variable, which can then be reassigned if the function is no longer needed.

Example:
```swift
func multiply(a, b) {
	var result = 0

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

The `copy` function takes in one argument (which must be an array, dictionary, or string) and returns a copy of it.

The `len` function takes in one argument (which must be an array or string) and returns its length.

The `print` function takes in a variable number of arguments and prints all of them, separated by newlines.

The `randint` function takes in two arguments (which must both be numbers), the first of which is optional (defaults to `1`), and returns a random integer between those two arguments (inclusive).

The `range` function takes in three arguments (which must all be numbers), the first and last of which are optional (both default to `1`), and returns an array containing every integer between the first and second arguments (inclusive), skipping over any integer that, when subtracted by the first argument, is not divisible by the third argument.

The `typeof` function takes in one argument and returns its type as a string.


The `array.__init` function takes in one argument, attempts to convert the argument to a string, and returns an array containing every character of that string.

The `array.contains` function takes in one argument and returns `true` if the array contains the argument (or `false` if it doesn't contain the argument).

The `array.find` function takes in one argument and returns an array containing every index at which that element occurs in the array.

The `array.insert` function takes in two arguments (the second of which must be a number), the second of which is optional (defaults to `-1`), inserts the first argument into the array at the index equal to the second argument, and returns the resulting array.

The `array.randelement` function takes in no arguments and returns a random element from the array.

The `array.remove` function takes in one argument (which must be a number), removes the element at the index equal to it from the array, and returns the resulting array.

The `array.reverse` function takes in no arguments, reverses the order of the elements in the array, and returns the resulting array.

The `array.sort` function takes in one argument (which must be a boolean), which is optional (defaults to `false`), sorts the array in ascending order (unless the argument is `true`, in which case the array would be sorted in descending order), and returns the resulting array.


The `boolean.__init` function takes in one argument and returns `true` if the argument is `"true"` or a non-zero number, or returns `false` if the argument is `"false"` or `0`.


The `dictionary.__init` function takes in one argument and, if the argument is an array, for each even index in that array, stores the element at that index as a key inside a dictionary (which is returned when completed), and stores the following element as that key's value.

The `dictionary.contains` function takes in one argument and returns `true` if the dictionary contains the argument (or `false` otherwise).

The `dictionary.find` function takes in one argument and returns an array containing every key at which that value occurs in the dictionary.

The `dictionary.insert` function takes in two arguments, inserts the first argument into the dictionary with a key equal to the second argument, and returns the resulting dictionary.

The `dictionary.keys` function takes in no arguments and returns an array containing all of the keys of the dictionary.

The `dictionary.remove` function takes in one argument, removes the value at the key equal to it from the dictionary, and returns the resulting dictionary.

The `dictionary.values` function takes in no arguments and returns an array containing all of the values of the dictionary.


The `number.__init` function takes in one argument and returns `1` if the argument is `true`, `0` if the argument is `false`, or a number from a string if the string is able to be parsed as a number.


The `string.capitalize` function takes in no arguments, makes the first character of each substring (separated by spaces) in the string an uppercase letter (if possible), and returns the resulting string.

The `string.decapitalize` function takes in no arguments, makes the first character of the string a lowercase letter (if possible), and returns the resulting string.

The `string.endswith` function takes in one argument and returns `true` if the string's last character is equal to the argument (or `false` otherwise).

The `string.lower` function takes in no arguments, makes all characters of the string uppercase letters (if possible), and returns the resulting string.

The `string.upper` function takes in no arguments, makes all characters of the string lowercase letters (if possible), and returns the resulting string.

The `string.startswith` function takes in one argument and returns `true` if the string's first character is equal to the argument (or `false` otherwise).

### Classes

Classes can be defined by the `class` keyword, followed by the class's name, then its body (enclosed in braces). Any variables declared inside the body can be used as properties, and any functions defined inside the body can be used as methods. A class's traits can all be referenced by using dot notation. Note that the first parameter of any class method is reserved for the current class instance. Any example Firic code with classes will always call this parameter `self`, but it can have any name.

Example:
```swift
class Person {
	var name

	func __init(self, name) {
		self.name = name.lower().capitalize()
	}


	func greet(self, person) {
		print(self.name + " says \"Hello, " + person.name +".\"");
	}
}

let foo = Person("foo")
let bar = Person("bar")
foo.greet(bar);
```
Output:
```
Foo says "Hello, Bar."
```

#### Inheritance

Classes can inherit traits from other classes. To do this, define a class, but place a less-than sign (`<`) followed by another class's name before the body. This will allow the class being defined to use all methods and properties from the inherited class.

Example:
```swift
class Animal {
	var type
	var name
}


class Cat < Animal {
	type = "Feline"

	func __init(self, name) {
		self.name = name.lower().capitalize()
	}
}

class Dog < Animal {
	type = "Canine"

	func __init(self, name) {
		self.name = name.lower().capitalize()
	}
}


let cat = Cat("tacocat")
let dog = Dog("dog god")

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

`__string`: tostring converter

### Enums

Enums can be defined using the `enum` keyword, followed by the enum's name, then its body (enclosed in braces). An enum's body should contain a list of comma-separated values, like an array, except these values are called cases, and can be referenced like class traits (using dot notation).

Example:
```swift
enum AnimalType {
	Feline,
	Canine,
}



class Animal {
	var type
	var name
}


class Cat < Animal {
	type = AnimalType.Feline

	func __init(self, name) {
		self.name = name.lower().capitalize()
	}
}

class Dog < Animal {
	type = AnimalType.Canine

	func __init(self, name) {
		self.name = name.lower().capitalize()
	}
}


let cat = Cat("tacocat")
let dog = Dog("dog god")

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

## Using Firic

Firic does not have a REPL (but it will in the future). Instead, to run any Firic code, you must create a file with the `.fi` file extension, then run the `main.lua` file with the path of the Firic file (the `firic.bat` (Windows) and `firic.sh` (Linux) files do this).
