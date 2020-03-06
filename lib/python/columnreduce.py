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
result = ['fileS2701.csv', 'fileS2503.csv', 'fileS1101.csv', 'fileS2506.csv', 'fileS1701.csv', 'fileS2504.csv', 'fileS2704.csv', 'fileS2703.csv', 'fileS0101.csv']
print(result)
#file=input("What csv file do you wish to load? ")
#newfile=file
begin = 0
end = 160

for x in result:
    with open(os.path.join(importpath,x), "r") as file_in:
        with open(os.path.join(exportpath,x), "w") as file_out:

            writer = csv.writer(file_out)

            for row in csv.reader(file_in):
                writer.writerow(row[begin:end])
