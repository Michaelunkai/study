from googleapiclient.discovery import build
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Define your API key and playlist ID
API_KEY = "Your_API_Key_Here"
PLAYLIST_ID = "Your_Playlist_ID_Here"

def main():
    # Build the YouTube Data API service using your API key
    youtube = build("youtube", "v3", developerKey=API_KEY)

    # Retrieve all videos in the specified playlist
    playlist_items_response = youtube.playlistItems().list(
        part="snippet",
        playlistId=PLAYLIST_ID,
        maxResults=50
    ).execute()

    playlist_items = playlist_items_response.get("items", [])

    if not playlist_items:
        print("No videos found in the playlist.")
        return

    # Get titles of videos in the playlist
    video_titles = [playlist_item["snippet"]["title"] for playlist_item in playlist_items]

    # Initialize TF-IDF vectorizer
    tfidf_vectorizer = TfidfVectorizer()

    # Fit and transform the data
    tfidf_matrix = tfidf_vectorizer.fit_transform(video_titles)

    # Compute similarity scores
    similarity_matrix = cosine_similarity(tfidf_matrix, tfidf_matrix)

    # Recommend videos based on similarity
    for i, video_item in enumerate(playlist_items):
        video_title = video_item["snippet"]["title"]
        video_id = video_item["snippet"]["resourceId"]["videoId"]
        print(f"Recommendations for '{video_title}':")
        
        # Get the similarity scores for this video
        similarity_scores = similarity_matrix[i]

        # Sort indices based on similarity scores
        similar_indices = similarity_scores.argsort()[::-1]

        # Exclude the current video itself
        similar_indices = similar_indices[1:]

        # Print top 5 recommendations
        for index in similar_indices[:5]:
            similar_video_id = playlist_items[index]["snippet"]["resourceId"]["videoId"]
            similar_video_title = get_video_title(youtube, similar_video_id)
            print(f"- {similar_video_title} (https://www.youtube.com/watch?v={similar_video_id})")

def get_video_title(youtube, video_id):
    video_response = youtube.videos().list(
        part="snippet",
        id=video_id
    ).execute()
    return video_response["items"][0]["snippet"]["title"]

if __name__ == "__main__":
    main()
