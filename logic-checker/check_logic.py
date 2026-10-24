"""Check a CSV truth table against SymPy Boolean equations.

Usage: logic-check equations.txt table.csv
Files are loaded from the equations/ and tables/ folders beside this script.
CSV headers may use any distinct signal names valid in an equation.
Equation left sides identify which CSV columns are outputs.
Example: v0 = i1 & ~mysignal. Expressions can span multiple lines.
XOR supports ^ or Xor(...). XNOR supports Xnor(...) or Equivalent(...).
"""

import argparse
import csv
from itertools import product
import keyword
from pathlib import Path
import re
import sys

from sympy import Symbol, false, true
from sympy.logic.boolalg import Boolean, Equivalent, Xor
from sympy.parsing.sympy_parser import parse_expr


def read_table(path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.reader(stream, strict=True)
        headers = [name.strip() for name in next(reader, [])]
        if not headers or len(set(headers)) != len(headers):
            raise ValueError("CSV needs a header with unique column names.")
        for name in headers:
            if not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", name):
                raise ValueError(f"Invalid signal name in CSV: {name!r}.")
            reserved = {"True", "False", "None", "Xor", "Xnor", "Equivalent"}
            if keyword.iskeyword(name) or name in reserved:
                raise ValueError(f"Reserved signal name in CSV: {name!r}.")
        rows = []
        for cells in reader:
            if not cells:
                continue
            line = reader.line_num
            if len(cells) != len(headers):
                raise ValueError(f"CSV line {line}: wrong number of cells.")
            values = [cell.strip().upper() for cell in cells]
            if any(value not in {"0", "1", "X"} for value in values):
                raise ValueError(f"CSV line {line}: use only 0, 1, or X.")
            rows.append((line, dict(zip(headers, values))))
        if not rows:
            raise ValueError("CSV contains no data rows.")
    return headers, rows


def read_equations(path, symbols):
    equations = {}
    namespace = {
        "true": true,
        "false": false,
        "Xor": Xor,
        "Xnor": Equivalent,
        "Equivalent": Equivalent,
        **symbols,
    }
    raw_source = path.read_text(encoding="utf-8")
    source = "\n".join(
        raw_line.split("#", 1)[0]
        for raw_line in raw_source.splitlines()
    )
    declarations = list(re.finditer(
        r"(?m)^[ \t]*([^=\s]+)[ \t]*=",
        source,
    ))
    prefix = source[:declarations[0].start()] if declarations else source
    if prefix.strip():
        line = next(
            number
            for number, text in enumerate(prefix.splitlines(), 1)
            if text.strip()
        )
        raise ValueError(f"Equation line {line}: missing '='.")

    for index, declaration in enumerate(declarations):
        line = source.count("\n", 0, declaration.start()) + 1
        target = declaration.group(1)
        end = (
            declarations[index + 1].start()
            if index + 1 < len(declarations)
            else len(source)
        )
        expression = " ".join(source[declaration.end():end].split())
        if target not in symbols:
            raise ValueError(
                f"Equation line {line}: output {target!r} is not "
                "a CSV column."
            )
        if target in equations:
            raise ValueError(f"Equation line {line}: duplicate {target}.")

        # Restrict the text before SymPy's evaluator sees it. SymPy still
        # handles all expression parsing and operator precedence.
        tokens = re.findall(r"[A-Za-z_][A-Za-z_0-9]*|\S", expression)
        unknown = [
            token for token in tokens
            if re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", token)
            and token not in namespace
        ]
        if unknown:
            raise ValueError(
                f"Equation line {line}: signal {unknown[0]!r} is not "
                "a CSV column."
            )
        allowed = set(namespace) | {"&", "|", "~", "^", "(", ")", ","}
        if not tokens or any(token not in allowed for token in tokens):
            raise ValueError(
                f"Equation line {line}: use &, |, ~, ^, Xor(...), "
                "Xnor(...), Equivalent(...), parentheses, or CSV "
                "signal names."
            )
        try:
            parsed = parse_expr(
                expression,
                local_dict=namespace,
                global_dict={"__builtins__": {}},
                transformations=(),
            )
        except Exception as error:
            raise ValueError(
                f"Equation line {line}: invalid expression: {expression}"
            ) from error
        if not isinstance(parsed, Boolean):
            raise ValueError(f"Equation line {line}: expected Boolean logic.")
        equations[target] = (expression, parsed)
    if not equations:
        raise ValueError("Equation file contains no equations.")
    return equations


def check_rows(inputs, outputs, rows, symbols, equations):
    failed = False
    checked = 0
    for line, row in rows:
        failures = []
        for output in outputs:
            if row[output] == "X":
                continue
            checked += 1
            source, expression = equations[output]
            substitutions = {}
            unknown = []
            # Only expand X inputs that this equation actually depends on.
            for name in inputs:
                symbol = symbols[name]
                if symbol not in expression.free_symbols:
                    continue
                if row[name] == "X":
                    unknown.append(name)
                else:
                    substitutions[symbol] = row[name] == "1"
            for bits in product((False, True), repeat=len(unknown)):
                values = dict(substitutions)
                values.update(zip((symbols[n] for n in unknown), bits))
                actual = int(bool(expression.subs(values)))
                if actual != int(row[output]):
                    detail = (
                        f"  {output} = {source}: expected {row[output]}, "
                        f"got {actual}"
                    )
                    if unknown:
                        witness = ", ".join(
                            f"{name}={int(bit)}"
                            for name, bit in zip(unknown, bits)
                        )
                        detail += f" (with {witness})"
                    failures.append(detail)
                    break
        if failures:
            failed = True
            print(f"FAIL: CSV line {line}")
            print("  " + ", ".join(f"{k}={v}" for k, v in row.items()))
            print("\n".join(failures))
    if checked == 0:
        raise ValueError("Nothing to check: all output values are X.")
    if failed:
        return 1
    print("check")
    return 0


def main():
    parser = argparse.ArgumentParser(prog="logic-check", description=__doc__)
    parser.add_argument("equations_file", help="filename inside equations/")
    parser.add_argument("csv_file", help="filename inside tables/")
    args = parser.parse_args()
    try:
        for name in (args.equations_file, args.csv_file):
            if Path(name).name != name or name in {".", ".."}:
                raise ValueError("Use filenames only, without folder paths.")
        folder = Path(__file__).resolve().parent
        table_path = folder / "tables" / args.csv_file
        equations_path = folder / "equations" / args.equations_file
        headers, rows = read_table(table_path)
        symbols = {name: Symbol(name) for name in headers}
        equations = read_equations(equations_path, symbols)
        outputs = list(equations)
        return check_rows(headers, outputs, rows, symbols, equations)
    except (OSError, UnicodeError, ValueError, csv.Error) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
