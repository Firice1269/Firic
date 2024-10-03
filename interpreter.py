import re
from sys import argv

argv: list[str] = ["interpreter.py", "(filename)"]

debug: bool = input("Enable Debug Mode? (Y/N) ").lower().startswith("y")

deliminator: str = " "
file_extension: str = "fi"

keywords: list[str] = ["comment", "end", "func", "print", "var"]
operations: list[str] = ["**", "*", "/", "%", "+", "-", "="]

functions: dict[str, str] = {}
variables: dict[str, str] = {}


def value_check(list: list[str], index: int):
    try:
        return list[index]
    except IndexError:
        return "Null"


def throw_error(file: str, line: list[tuple[str, str]], error_message: str):
    print(f"\033[31mERROR:\033[0m File: {file}, Line: {line}, Error Message: {error_message}")


def tokenize(contents: str):
    # Separate Lines
    lines = contents.split("\n")
    tokenized_lines = []

    for line in lines:
        characters = list(line)
        tokens = []
        items = []

        quotes = 0
        temporary_token = ""

        for character in characters:
            # Check Strings
            if character == '"':
                quotes += 1

            if quotes % 2 == 0:
                string = False
            else:
                string = True

            # Separate Tokens
            if character == deliminator and string == False:
                tokens.append(temporary_token)
                temporary_token = ""
            else:
                temporary_token += character

        # Append Tokens
        if len(temporary_token) != 0:
            tokens.append(temporary_token)

        # Check Types
        for token in tokens:
            # String
            if (token[0] == '"' and token[-1] == '"') or (token[0] == "'" and token[-1] == "'"):
                items.append(("string", token))

            # Keyword
            if re.match(r"[.a-z]+", token):
                items.append(("keyword", token))

            # Operation
            if token in operations:
                items.append(("operation", token))

            # Number
            if re.match(r"[.0-9]+", token):
                items.append(("number", token))

        tokenized_lines.append(items)
    return tokenized_lines


def parse(file: str):
    contents = open(file, "r").read()
    lines = tokenize(contents)

    error = False

    function = False
    function_name = ""
    function_code = ""

    for line_index, line in enumerate(lines):
        python_code = ""

        for token_index, token in enumerate(line):
            # Keywords
            if token[0] == "keyword":
                # Printing
                if token[1] == "print":
                    python_code += "print("

                    for i in line[token_index + 1:]:
                        if i[1] in keywords:
                            error = True
                            throw_error(file, lines.index(line) + 1, "Cannot call keywords in a print statement.")
                        elif i[1] == "=":
                            error = True
                            throw_error(file, lines.index(line) + 1, "Cannot assign variables in a print statement.")
                        else:
                            python_code += f" {i[1]} "

                    python_code += ")"

                # Defining Functions
                if token[1] == "func":
                    if value_check(line, token_index + 1)[1] in functions:
                        error = True
                        throw_error(file, lines.index(line) + 1, "Cannot define an already existing function.")
                    elif value_check(line, token_index + 1) == "Null":
                        error = True
                        throw_error(file, lines.index(line), "Cannot define an unnamed function.")
                    else:
                        function = True
                        function_name += f"{line[token_index + 1][1]}"

                        python_code += f'functions["{function_name}"] = ""'
                        exec(python_code)

                # Ending Functions
                if token[1] == "end":
                    if function:
                        python_code += f'functions["{function_name}"] = "{function_code}"'

                        function = False
                        function_name = ""
                        function_code = ""
                    else:
                        error = True
                        throw_error(file, lines.index(line) + 1, "Cannot end a nonexistent function.")

                # Functions & Variables
                if token[1] not in keywords:
                    # Calling Functions
                    if token[1] in functions:
                        python_code += functions[token[1]]

                    # Declaring Variables
                    elif value_check(line, token_index - 1)[1] == "var":
                        if token[1] in variables:
                            error = True
                            throw_error(file, lines.index(line) + 1, "Cannot declare an already existing variable.")
                        else:
                            python_code += f'variables["{token[1]}"] = {line[token_index + 1][1]}'

                    # Assigning Variables
                    elif value_check(line, token_index + 1)[1] == "=":
                        if token[1] in variables:
                            python_code += f'variables["{token[1]}"]'

                            for i in line[token_index + 1:]:
                                python_code += f" {i[1]} "
                        else:
                            error = True
                            throw_error(file, lines.index(line) + 1, "Cannot assign a nonexistent variable.")

                    # Referencing Variables
                    elif token[1] in variables:
                        if variables[token[1]] == str(variables[token[1]]):
                            python_code = python_code.replace(token[1], f'"{variables[token[1]]}"')
                        else:
                            python_code = python_code.replace(token[1], str(variables[token[1]]))

                    # Detecting Undefined
                    elif value_check(line, 0)[1] != "comment":
                        error = True
                        throw_error(file, lines.index(line) + 1, "Undefined keyword, function, or variable.")

        # Debug Mode
        if debug:
            print(line)
            print(python_code)

        if function and value_check(line, 0)[1] != "func" and python_code != "":
            function_code += f"{python_code}; "
        elif error:
            break
        else:
            exec(python_code)


if argv[-1].split(".")[1] == file_extension:
    parse(argv[-1])
