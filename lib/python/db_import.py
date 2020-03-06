from sqlalchemy import create_engine
import pandas as pd

file=input("What csv file do you wish to load? ")
tablename = file.rsplit( ".", 1 )[ 0 ]


df = pd.read_csv(file, sep=',')
# Optional, set your indexes to get Primary Keys
#df = df.set_index(['COL A', 'COL B'])

engine = create_engine('mysql://root:vbseut@localhost/us_census', echo=False)

df.to_sql(tablename, engine, index=False)
