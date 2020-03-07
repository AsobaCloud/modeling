import glob
import json

glob_data = []
for file in glob.glob('*.json'):
    with open(file) as json_file:
        data = json.load(json_file)

        i = 0
        while i < len(data):
            glob_data.append(data[i])
            i += 1

with open('finalFile.json', 'w') as f:
    json.dump(glob_data, f, indent=4)
