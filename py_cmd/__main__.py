import os
import shutil
import json
from typing import Union, Optional, List
from pathlib import Path
from datetime import date
from itertools import groupby
from dataclasses import dataclass, field, _is_dataclass_instance

from .mk_cmd import cmd, parse_cmd
from .extend_dataclasses import extend_dataclass, field_meta as fm, as_dict


@extend_dataclass
@dataclass
class Record:
    Type: str
    Tag: Optional[str] = None
    Subtag: Optional[str] = None
    Description: Optional[Union[str, List[str]]] = None
    Added: Optional[str] = None
    Deprecated: Optional[str] = None
    Preferred_Value: Optional[str] = field(
        default=None, metadata=fm(alias="Preferred-Value")
    )
    Prefix: Optional[Union[str, List[str]]] = None
    Suppress_Script: Optional[str] = field(
        default=None, metadata=fm(alias="Suppress-Script")
    )
    Macrolanguage: Optional[str] = None
    Scope: Optional[str] = None
    Comments: Optional[str] = None


def _parse(content: str):
    def parse_record(raw_record: str) -> Record:
        d = {}
        for field in raw_record.replace("\n ", "").splitlines():
            p = field.find(":")
            name = field[:p].strip()
            value = field[p + 1 :].strip()
            # Maybe the same field appears multiple times
            v: Union[str, list, None] = d.get(name)
            if type(v) is str:
                d[name] = [v, value]
            elif type(v) is list:
                v.append(value)
            else:
                d[name] = value
        return Record(**d)

    return [parse_record(raw_record) for raw_record in content.split("%%\n")[1:]]


path_here = Path(__file__).parent
dir_language_registry = path_here.joinpath("../language_registry")
local_registry = dir_language_registry.joinpath("language-subtag-registry")
dir_v_files = path_here.joinpath("../i18n/language")


@cmd
def dl_registry():
    """Download language subtag registry & update local `anguage-subtag-registry`."""
    import urllib.request

    def parse_field(b: bytes):
        return b.decode("utf-8").strip().split(": ")

    def show_progress(block_num, block_size, total_size):
        print(f"  {block_num * block_size}/{total_size}", end="\r")

    file_date = None

    if local_registry.is_file():
        with local_registry.open("rb") as fp:
            file_date = date.fromisoformat(parse_field(fp.readline())[1])

    src = "http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry"

    temp_filename, _ = urllib.request.urlretrieve(src, reporthook=show_progress)

    is_latest = False
    with open(temp_filename, "rb") as fp:
        remote_date = date.fromisoformat(parse_field(fp.readline())[1])
        fp.seek(0)
        if file_date and remote_date == file_date:
            is_latest = True
    if not is_latest:
        if not local_registry.parent.exists():
            local_registry.parent.mkdir()
        shutil.copyfile(temp_filename, local_registry)
    else:
        print("The local file is the latest version.")
    os.remove(temp_filename)


@cmd
def registry_to_json():
    """Parse local `anguage-subtag-registry` to json files"""
    with local_registry.open("r") as fp:
        content = fp.read()
    records = _parse(content)
    for k, g in groupby(records, key=lambda r: r.Type):
        with dir_language_registry.joinpath(f"{k}.json").open("w") as fp:
            json.dump([as_dict(r) for r in g], fp, indent=2)


@cmd
def registry_to_v():
    """Parse local `anguage-subtag-registry` to v files"""
    with local_registry.open("r") as fp:
        content = fp.read()
    records = _parse(content)

    suppress_script_dict = {}
    for k, g in groupby(records, key=lambda r: r.Type):
        result_set = set()

        for r in g:
            if r.Deprecated is not None:
                continue
            if r.Description == "Private use":
                continue

            tag = (
                r.Preferred_Value
                if r.Preferred_Value
                else (r.Subtag if r.Subtag else r.Tag)
            )

            if k == "language":
                if r.Suppress_Script:
                    suppress_script_dict[tag] = r.Suppress_Script
                result_set.add(tag)
                continue
            if k == "extlang":
                if type(r.Prefix) is str:
                    result_set.add(f"{r.Prefix}-{tag}")
                continue
            if k == "variant":
                if tag in (
                    "alalc97" "fonipa",
                    "fonkirsh",
                    "fonnapa",
                    "fonupa",
                    "fonxsamp",
                    "simple",
                ):
                    continue

                suppress_prefix = tuple(
                    f"{k}-{v}" for k, v in suppress_script_dict.items()
                )
                if type(r.Prefix) is str:
                    if r.Prefix not in suppress_prefix:
                        result_set.add(f"{r.Prefix}-{tag}")
                    continue
                if type(r.Prefix) is list:
                    for prefix in r.Prefix:
                        if r.Prefix not in suppress_prefix:
                            result_set.add(f"{prefix}-{tag}")
                continue

            result_set.add(tag)

        # write v file
        p = dir_v_files.joinpath(f"{k}.v")
        with p.open("w") as fp:
            if k == "language":
                fp.writelines(
                    [
                        "module language\n",
                        "\n",
                        f"pub const suppress_scripts = map{suppress_script_dict}\n",
                        "\n",
                        f"pub const {k}s = {list(sorted(result_set))}\n",
                    ]
                )
            else:
                fp.writelines(
                    [
                        "module language\n",
                        "\n",
                        f"pub const {k}s = {list(sorted(result_set))}\n",
                    ]
                )
        print(f"Export {p.absolute()}")

    import subprocess

    subprocess.run(["v", "-w", "fmt", dir_v_files.absolute()])


if __name__ == "__main__":
    parse_cmd()
