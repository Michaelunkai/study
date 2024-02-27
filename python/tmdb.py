import requests
import pandas as pd

# Function to fetch movie data based on user's mood
def fetch_movies_by_mood(mood, api_key):
    url = "https://api.themoviedb.org/3/discover/movie"
    params = {
        'api_key': api_key,
        'language': 'en-US',
        'sort_by': 'popularity.desc',
        'include_adult': 'false',
        'with_genres': get_genre_id(mood, api_key),
        'page': 1
    }
    
    # Fetching the first page of results
    response = requests.get(url, params=params)
    if response.status_code == 200:
        results = response.json()['results']
        total_pages = response.json()['total_pages']
        
        # Fetching subsequent pages of results until we have at least 50 movies
        page = 2
        while len(results) < 50 and page <= total_pages:
            params['page'] = page
            response = requests.get(url, params=params)
            if response.status_code == 200:
                results.extend(response.json()['results'])
                page += 1
            else:
                print(f"Failed to fetch page {page} of data from TMDb API")
                break
        
        return results[:50]  # Return at most 50 movies
    else:
        print("Failed to fetch data from TMDb API")
        return None

# Function to get genre ID based on mood
def get_genre_id(mood, api_key):
    # Dictionary mapping moods to genre IDs
    mood_to_genre = {
        'happy': 35,  # Comedy
        'sad': 18,    # Drama
        'action': 28, # Action
        'scary': 27,  # Horror
        'romantic': 10749, # Romance
    }
    return mood_to_genre.get(mood.lower(), 18)  # Default to Drama if mood not found

# Function to recommend movies
def recommend_movies(mood, api_key):
    movies = fetch_movies_by_mood(mood, api_key)
    if movies:
        df = pd.DataFrame(movies)
        return df[['title', 'vote_average', 'release_date', 'overview']]
    else:
        return None

# Main function
def main():
    api_key = "aaf212050d3a56424a311c8fab681f11"
    mood = input("Enter your mood (happy, sad, action, scary, romantic): ")
    recommended_movies = recommend_movies(mood, api_key)
    if recommended_movies is not None:
        print("\nHere are recommended movies for your mood:")
        print(recommended_movies)
    else:
        print("Failed to get recommendations.")

if __name__ == "__main__":
    main()
