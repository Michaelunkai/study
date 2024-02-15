import praw

# Reddit API credentials
CLIENT_ID = 't7CCtuZqJrrYWshOGSng5A'
SECRET_KEY = 'b7D38g5cVOLlif0A_9OeZo7fgypXPw'
USERNAME = 'michaelovsky5'
PASSWORD = 'Blackablacka3'

# Create a Reddit instance
reddit = praw.Reddit(client_id=CLIENT_ID,
                     client_secret=SECRET_KEY,
                     username=USERNAME,
                     password=PASSWORD,
                     user_agent='myredditapi')

# Example: Get information about a subreddit
def get_subreddit_info(subreddit_name):
    subreddit = reddit.subreddit(subreddit_name)
    print(f"Name: {subreddit.display_name}")
    print(f"Title: {subreddit.title}")
    print(f"Description: {subreddit.description}")

# Example usage
subreddit_name = 'learnpython'  # You can change this to any subreddit name you want to get information about
get_subreddit_info(subreddit_name)
