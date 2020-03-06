import json
import glob

result = []
for f in glob.glob("*.json"):
    with open(f, "r") as infile:
        try:
            result.append(json.load(infile))
        except ValueError:
            print(f)

with open("merged_file.json", "w") as outfile:
    json.dump(result, outfile)
