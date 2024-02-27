import pandas as pd
from sklearn.neighbors import NearestNeighbors
from fuzzywuzzy import process

# Load IMDb datasets into Pandas DataFrames
title_basics_df = pd.read_csv("/c/Users/micha/Downloads/title.basics.tsv.gz", sep='\t', compression='gzip')
title_ratings_df = pd.read_csv("/c/Users/micha/Downloads/title.ratings.tsv.gz", sep='\t', compression='gzip')

# Merge relevant columns
merged_df = pd.merge(title_basics_df, title_ratings_df, on='tconst', how='inner')

# Create user-movie rating matrix
user_item_matrix = merged_df.pivot_table(index='primaryTitle', values='averageRating', aggfunc='mean')

# Define a KNN model on cosine similarity
cf_knn_model = NearestNeighbors(metric='cosine', algorithm='brute', n_neighbors=10, n_jobs=-1)

# Fitting the model on our matrix
cf_knn_model.fit(user_item_matrix)

# Define function to provide movie recommendations
def movie_recommender_engine(movie_name, matrix, cf_model, n_recs):
    # Extract input movie ID
    movie_id = process.extractOne(movie_name, matrix.index)[2]
    
    # Calculate neighbour distances
    distances, indices = cf_model.kneighbors(matrix.iloc[movie_id, :].values.reshape(1, -1), n_neighbors=n_recs)
    movie_rec_ids = sorted(list(zip(indices.squeeze().tolist(), distances.squeeze().tolist())), key=lambda x: x[1])[:0:-1]
    
    # List to store recommendations
    cf_recs = []
    for i in movie_rec_ids:
        cf_recs.append({'Title': matrix.index[i[0]], 'Distance': i[1]})
    
    # Select top number of recommendations needed
    df = pd.DataFrame(cf_recs, index=range(1, n_recs+1))
     
    return df

# Get movie recommendations
movie_title = input("Enter a movie title: ")
n_recs = 10
recommendations = movie_recommender_engine(movie_title, user_item_matrix, cf_knn_model, n_recs)
print("Recommendations for '{}':".format(movie_title))
print(recommendations)
