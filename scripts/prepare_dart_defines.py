import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a dotenv or JSON environment file for Flutter defines."
    )
    parser.add_argument("--input", default=".env")
    parser.add_argument("--output", default=".dart-defines.json")
    args = parser.parse_args()

    input_path = Path(args.input)
    contents = input_path.read_text(encoding="utf-8").strip()
    if contents.startswith("{"):
        values = json.loads(contents)
        if not isinstance(values, dict):
            raise ValueError(f"{input_path} must contain a JSON object.")
        defines = {str(key): str(value) for key, value in values.items()}
    else:
        defines = {}
        for line_number, line in enumerate(contents.splitlines(), start=1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            key, separator, value = line.partition("=")
            if not separator or not key.strip():
                raise ValueError(
                    f"{input_path}:{line_number}: expected KEY=value."
                )
            defines[key.strip()] = value.strip()

    Path(args.output).write_text(
        json.dumps(defines, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
