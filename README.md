Here is a clean, professional `README.md`. I have automatically corrected the URL in the install command to point to the **raw** version of the script, otherwise piping it to `bash` would fail.

***

# manpy

**manpy** is a beautiful, modern alternative to Python's built-in `help()` or `man` pages. It allows you to inspect modules, classes, and function signatures directly from your terminal with syntax highlighting, smart member listings, and direct paging.

## ⚡ Quick Install

Copy and paste this one-liner to install `manpy` (updates `.bashrc`/`.zshrc` automatically):

```bash
curl -sL https://raw.githubusercontent.com/TheValiant/manpy/main/install.sh | bash
```

## 🚀 Usage

Simply use `manpy` followed by any Python import path. It dynamically resolves libraries without needing to manually open a Python shell.

```bash
# Inspect a module
manpy os

# Inspect a nested function
manpy random.randint

# Inspect a class
manpy collections.Counter
```

## ✨ Features

*   **Syntax Highlighting:** Full colored output for source code and signatures.
*   **Smart Resolution:** Works on built-ins, standard libraries, and installed pip packages.
*   **Intelligent Views:**
    *   **Functions:** Shows signature, docstring, and source code.
    *   **Classes/Modules:** Shows docstring and a clean table of public methods/members.
*   **Error Handling:** Smartly pages output using `less`, but prints directly to stdout if an error occurs so you don't miss the message.

## Requirements

*   Python 3+
*   [Rich](https://github.com/Textualize/rich) (Installed automatically by the script)
