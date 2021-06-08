__all__ = ["cmd", "parse_cmd"]

import sys
from typing import Callable


def cmd(fn: Callable):
    """A decorator binding the callable object as a command.
    - Command name is callable object name.
    - Command description is callable object docstring.
    - Duplicate commands will not override previous command.
    """
    if not hasattr(cmd, "_callables"):
        cmd._callables = {}
    if "help" not in cmd._callables:

        def help():
            """Helping imformation."""
            print("Use: {} <command>".format(sys.argv[0]))
            print("Commands:")
            w = max(len(k) for k in cmd._callables)
            for k, fn in cmd._callables.items():
                print(f" {str(k).ljust(w)}  {fn.__doc__}")

        cmd._callables["help"] = help
    if callable(fn):
        cmd._callables.setdefault(fn.__name__, fn)
    return fn


def parse_cmd():
    """Parse command line arguments to invoke available commands.

    Only one `<command>` argument is currently supported.
    """
    if len(sys.argv) < 2:
        print("Use: {} <command>".format(sys.argv[0]))
        sys.exit(0)
    cmd(...)  # initialization
    fn = cmd._callables.get(sys.argv[1])
    if callable(fn):
        fn()
    else:
        print("Please use `{} help` to see available commands.".format(sys.argv[0]))
