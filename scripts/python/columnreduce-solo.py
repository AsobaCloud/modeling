import os
import pandas
import glob
import csv

# If you want to remove the first column and then every column after the fifth, keeping
# in mind that Python indexes start at 0
importpath = '/home/shingai/box1/export'
exportpath = '/home/shingai/box1/export/columnreduce'
extension = 'csv'
os.chdir(importpath)
#result = [i for i in glob.glob('*.{}'.format(extension))]

file=input("What csv file do you wish to load? ")
#newfile=file
begin1 = 0
end1 = 2
begin2 = 161
end2 = 250

with open(os.path.join(importpath,file), "r") as file_in:
    with open(os.path.join(exportpath,file), "w") as file_out:
        writer = csv.writer(file_out)

        for row in csv.reader(file_in):
            writer.writerow(row[begin1:end1] + row[begin2:end2])
