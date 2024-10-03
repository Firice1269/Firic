# Firic
A programming language, made by me, Firice (obviously), programmed in Python.

For those that are too lazy to open up the documentation:

## Documentation
### Comments
Comments are strings of text that the program ignores, and instead of being instructions for the program to follow, they are typically left as notes for a developer or user of the program.

In Firic, comments are written as "comment {commented text}", where {commented text} is the information that the developer or user wishes to be commented out.
	
For example,

Python:

\# This is a comment.
	
Firic:

comment This is a comment.

Output:



### Print Statements
Print statements are built-in functions that allow information to be placed in the output terminal. Print statements are typically used for debugging purposes or communicating with a user. In Firic, print statements are written as "print {printed information}", where {printed information} is the information that the developer or user wishes to be printed to the output.
	
For example,

Python:

print("Hello, world!")
	
Firic:

print "Hello, world!"

Output:

Hello, world!

### Variables
Variables are objects that store data. They can be declared with a name and data to be stored, assigned to new values, or have their current values referenced by the program.

In Firic, variables are declared as "var {variable name} {variable value}", where {variable name} is the name given to the variable, and {variable value} is the value given to the variable, variables are assigned as "{variable name} = {new value}", where {variable name} is the name of the variable, and {new value} is the value that the variable is being assigned to, and variables are referenced as "{variable name}", where {variable name} is the name of the variable.

For example,

Python:

text = "Hello, world!"
print(text)
text = "Goodbye, world!"
print(text)

Firic:

var text "Hello, world!"
print text
text = "Goodbye, world!"
print text

Output:

Hello, world!
Goodbye, world!

### Functions
Functions, much like variables, are objects that store data. However, unlike variables, which store values, functions store lines of code. Functions can be defined with a name and a block of code, or called on to execute the code stored. Also unlike variables, functions cannot have their values changed.

In Firic, functions are defined as "func {function name}", where {function name} is the name given to the function. Then, on new lines, the code stored inside the function should be written. Finally, after the final line of the function's code, a line containing "end" should be written to signal to the program that the function has ended. Functions are called as "{function name}", where {function name} is the name of the function.

For example,

Python:

num1 = 12
num2 = 69
def add():
	print(num1 + num2)
add()

Firic:

var num1 12
var num2 69
func add
print num1 + num2
end
add

Output:

81


### Creating & Running Files
To create a Firic file, give it a name, and then give it the file extension ".fi" (the file extension that Firic uses). Then, to run that file:

1. Go into the "interpreter.py" file.
2. Change "(filename)" on line 4 to the name of your file (including its file extension).
3. Run the "interpreter.py" file.
