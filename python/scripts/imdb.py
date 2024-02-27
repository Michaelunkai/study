import pandas as pd

# Load IMDb datasets into Pandas DataFrames
title_basics_df = pd.read_csv("/c/Users/micha/Downloads/title.basics.tsv.gz", sep='\t', compression='gzip', dtype=str)
title_ratings_df = pd.read_csv("/c/Users/micha/Downloads/title.ratings.tsv.gz", sep='\t', compression='gzip')

# Merge relevant columns
merged_df = pd.merge(title_basics_df, title_ratings_df, on='tconst', how='inner')

# Show all movies in the database
all_movies = merged_df['primaryTitle'].unique()
print("All movies in the database:")
for movie in all_movies:
    print(movie)
