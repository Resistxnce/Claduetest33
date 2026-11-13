#!/usr/bin/env python3
"""Build build/RedlineHighway.rbxlx from src/ without Rojo, using only Python's standard library.

Folders become Folders, *.server.luau files become Scripts, *.client.luau files LocalScripts and
other *.luau files ModuleScripts, placed in the same services as default.project.json. Open the
result in Roblox Studio with File > Open from File.

Usage: python3 tools/build_place.py
"""
import pathlib
from xml.sax.saxutils import escape

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
OUT = ROOT / "build" / "RedlineHighway.rbxlx"
GRAVITY = 9.81 / 0.28  # real gravity in studs/s^2 at 0.28 m per stud

SUFFIXES = (
    (".server.luau", "Script"),
    (".client.luau", "LocalScript"),
    (".luau", "ModuleScript"),
)


class PlaceWriter:
    def __init__(self):
        self.lines = []
        self.count = 0

    def open_item(self, class_name, name, properties=()):
        self.count += 1
        self.lines.append(f'<Item class="{class_name}" referent="RBX{self.count:08X}">')
        self.lines.append("<Properties>")
        self.lines.append(f'<string name="Name">{escape(name)}</string>')
        self.lines.extend(properties)
        self.lines.append("</Properties>")

    def close_item(self):
        self.lines.append("</Item>")


def cdata(text):
    # a CDATA section can't contain "]]>", so split it across two sections
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def script_kind(path):
    for suffix, class_name in SUFFIXES:
        if path.name.endswith(suffix):
            return class_name, path.name[: -len(suffix)]
    return None, None


def add_directory(writer, directory):
    for entry in sorted(directory.iterdir()):
        if entry.is_dir():
            writer.open_item("Folder", entry.name)
            add_directory(writer, entry)
            writer.close_item()
            continue
        class_name, name = script_kind(entry)
        if class_name:
            source = entry.read_text(encoding="utf-8")
            writer.open_item(class_name, name, [f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>'])
            writer.close_item()


def main():
    writer = PlaceWriter()
    writer.lines.append(
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
    )
    writer.open_item("Workspace", "Workspace", [f'<float name="Gravity">{GRAVITY:.4f}</float>',
                                                '<bool name="StreamingEnabled">false</bool>'])
    writer.close_item()
    for service in ("ReplicatedStorage", "ServerScriptService"):
        writer.open_item(service, service)
        add_directory(writer, SRC / service)
        writer.close_item()
    writer.open_item("StarterPlayer", "StarterPlayer")
    writer.open_item("StarterPlayerScripts", "StarterPlayerScripts")
    add_directory(writer, SRC / "StarterPlayer" / "StarterPlayerScripts")
    writer.close_item()
    writer.close_item()
    writer.lines.append("</roblox>")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(writer.lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)}: {writer.count} instances, {OUT.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
