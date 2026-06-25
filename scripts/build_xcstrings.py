#!/usr/bin/env python3
"""Assemble Localizable.xcstrings (Xcode String Catalog) from per-language JSON files."""
import json, glob, os, collections

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = json.load(open(os.path.join(HERE, "loc_strings.json")))
LOC_DIR = os.path.join(HERE, "loc")

# Load every translation file
langs = {}
for f in sorted(glob.glob(os.path.join(LOC_DIR, "*.json"))):
    code = os.path.splitext(os.path.basename(f))[0]
    langs[code] = json.load(open(f))

# Build the strings map. Keys preserve source order.
strings = collections.OrderedDict()
for key, en_value in SRC.items():
    localizations = collections.OrderedDict()
    # English source
    localizations["en"] = {
        "stringUnit": {"state": "translated", "value": en_value}
    }
    for code in sorted(langs.keys()):
        val = langs[code].get(key)
        if val is None:
            continue
        localizations[code] = {
            "stringUnit": {"state": "translated", "value": val}
        }
    strings[key] = {
        "extractionState": "manual",
        "localizations": localizations,
    }

catalog = collections.OrderedDict()
catalog["sourceLanguage"] = "en"
catalog["strings"] = strings
catalog["version"] = "1.0"

out = os.path.join(HERE, "..", "Solstice", "Localizable.xcstrings")
out = os.path.abspath(out)
with open(out, "w", encoding="utf-8") as fh:
    json.dump(catalog, fh, ensure_ascii=False, indent=2)
    fh.write("\n")

print(f"Wrote {out}")
print(f"{len(strings)} strings, {1 + len(langs)} languages (en + {len(langs)})")
