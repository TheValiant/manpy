#!/usr/bin/env python3

import sys
import importlib
import inspect
import builtins
from rich.console import Console
from rich.syntax import Syntax
from rich.panel import Panel
from rich.markdown import Markdown
from rich.text import Text
from rich.table import Table

def resolve_object(path):
    """
    Dynamically resolves a string path (e.g., 'os.path.join') to a Python object.
    """
    if hasattr(builtins, path):
        return getattr(builtins, path)
    parts = path.split('.')
    for i in range(len(parts), 0, -1):
        module_name = '.'.join(parts[:i])
        try:
            module = importlib.import_module(module_name)
            obj = module
            remaining_parts = parts[i:]
            for part in remaining_parts:
                obj = getattr(obj, part)
            return obj
        except (ImportError, AttributeError):
            continue
    raise ValueError(f"Could not find or import module/function: '{path}'")

def render_members(obj):
    """Creates a Rich Table to display members of a class or module."""
    table = Table(box=None)
    table.add_column("Member", style="cyan")
    table.add_column("Type", style="magenta")
    table.add_column("Description", no_wrap=False, style="green")

    try:
        members = inspect.getmembers(obj)
        public_members = [
            (name, member) for name, member in members if not name.startswith("_")
        ]

        for name, member in public_members:
            obj_type = type(member).__name__
            # For functions/methods, get a one-line docstring
            doc = (inspect.getdoc(member) or "").strip().split('\n')[0]
            table.add_row(name, obj_type, doc)

        return Panel(table, title="[bold blue]Members[/bold blue]", border_style="blue")
    except Exception:
        return None

def main():
    console = Console()

    if len(sys.argv) < 2:
        console.print("[bold red]Usage:[/bold red] python pyhelp.py <module.function_name>")
        console.print("[dim]Example: python pyhelp.py random.randint[/dim]")
        sys.exit(1)

    target_name = sys.argv[1]

    try:
        obj = resolve_object(target_name)
        
        title = Text(f"Inspecting: {target_name}", style="bold magenta reverse", justify="center")
        console.print()
        console.print(title)
        console.print()

        # --- NEW: General Information Panel ---
        info_table = Table.grid(expand=True, padding=(0, 1))
        info_table.add_column(style="bold yellow")
        info_table.add_column()
        info_table.add_row("Type:", str(type(obj).__name__))
        try:
            file_path = inspect.getfile(obj)
            info_table.add_row("File:", file_path)
        except TypeError:
            info_table.add_row("File:", "[dim]N/A (built-in object)[/dim]")
        console.print(Panel(info_table, title="[bold cyan]Info[/bold cyan]", border_style="cyan"))

        # --- NEW: Signature Panel ---
        if callable(obj) and not inspect.isclass(obj) and not inspect.ismodule(obj):
            try:
                sig = inspect.signature(obj)
                syntax = Syntax(f"def {target_name.split('.')[-1]}{sig}:", "python", theme="monokai")
                console.print(Panel(syntax, title="[bold yellow]Signature[/bold yellow]", border_style="yellow"))
            except (ValueError, TypeError): # Handles objects with no signature
                pass
        
        doc_string = inspect.getdoc(obj)
        if doc_string:
            md = Markdown(doc_string)
            console.print(Panel(md, title="[bold blue]Documentation[/bold blue]", border_style="blue"))
        else:
            console.print(Panel("[italic yellow]No docstring found.[/italic yellow]", title="Documentation", border_style="yellow"))

        # --- UPDATED: Source Code / Members ---
        if inspect.isclass(obj) or inspect.ismodule(obj):
            member_panel = render_members(obj)
            if member_panel:
                console.print(member_panel)
        else: # For functions, methods, etc., show source code.
            try:
                source_code = inspect.getsource(obj)
                syntax = Syntax(
                    source_code, 
                    "python", 
                    theme="monokai", 
                    line_numbers=True, 
                    word_wrap=True
                )
                console.print(Panel(syntax, title=f"[bold green]Source Code ({target_name})[/bold green]", border_style="green"))
            
            except (OSError, TypeError):
                error_msg = (
                    "[bold red]Source code not available.[/bold red]\n\n"
                    "This object is likely a built-in function or implemented in C."
                )
                console.print(Panel(error_msg, title="Source Code", border_style="red"))

    except ValueError as e:
        console.print(f"[bold red]Error resolving path:[/bold red] {e}")
        sys.exit(1)
    except Exception as e:
        console.print(f"[bold red]Unexpected error:[/bold red] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
