import requests
from colorama import init, Fore, Style
import webbrowser

# Initialize colorama to support ANSI escape sequences for colors
init(autoreset=True)

# Step 1: Setting Up Authentication
CLIENT_ID = 'XXXXXXXXXXXXX'
SECRET_KEY = 'XXXXXXXXXXXXX'
USERNAME = 'XXXXXXXXXXXXX'
PASSWORD = 'XXXXXXXXXXXXX'

# Step 2: Installing Required Libraries
# Run this command in your terminal or command prompt:
# pip install requests colorama

def fetch_reddit_data(url, headers, params=None):
    """
    Fetch data from Reddit API.
    
    Args:
        url (str): The URL to make the request.
        headers (dict): Headers to include in the request.
        params (dict, optional): Additional parameters for the request.

    Returns:
        dict: The JSON response.
    """
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"{Fore.RED}Error occurred: {e}")
        return None

def print_reddit_posts(data):
    """
    Print Reddit posts from JSON data.
    
    Args:
        data (dict or list): The JSON data received from the API.
    """
    if isinstance(data, dict):
        data_children = data.get('data', {}).get('children', [])
    elif isinstance(data, list):
        data_children = data
    else:
        print(f"{Fore.RED}Invalid data type.")
        return False
    
    if data_children:
        print(f"{Style.BRIGHT}{Fore.BLUE}{Style.BRIGHT + Fore.WHITE + 'Reddit Posts':^160s}")
        print("-" * 160)  # Separator for better readability
        
        for index, post in enumerate(data_children, start=1):
            post_data = post.get('data', {})
            subreddit_name = post_data.get('subreddit')
            print(f"{Style.BRIGHT}{Fore.RED}{Style.BRIGHT + Fore.RED + subreddit_name.upper():^160s}")
            print(f"{Style.BRIGHT}{Fore.GREEN}Post {index}:")
            print(f"{Style.BRIGHT}{Fore.GREEN}Title: {post_data.get('title')}")
            print(f"{Style.BRIGHT}{Fore.YELLOW}Author: {post_data.get('author')}")
            print(f"{Style.BRIGHT}{Fore.CYAN}Upvotes: {post_data.get('ups')}")
            print(f"{Style.BRIGHT}{Fore.MAGENTA}Comments: {post_data.get('num_comments')}")
            print(f"{Style.BRIGHT}{Fore.WHITE}URL: {post_data.get('url')}")
            print(f"{Style.BRIGHT}{Fore.WHITE}Score: {post_data.get('score')}")
            print(f"{Style.BRIGHT}{Fore.WHITE}Created UTC: {post_data.get('created_utc')}")
            print(f"{Style.BRIGHT}{Fore.WHITE}---------------------------------------------")
            print()
        
        return True
            
    else:
        print(f"{Fore.RED}Failed to fetch Reddit data.")
        return False

def open_post(url):
    """
    Open the post in a web browser.
    
    Args:
        url (str): The URL of the post.
    """
    try:
        webbrowser.open_new_tab(url)
    except Exception as e:
        print(f"{Fore.RED}Error opening post: {e}")

def search_reddit(query):
    """
    Search Reddit for specific topics, subreddits, or posts based on keywords or phrases.
    
    Args:
        query (str): The search query.

    Returns:
        dict: The JSON response containing search results.
    """
    url = 'https://www.reddit.com/search.json'
    headers = {
        'User-Agent': 'Custom User Agent/1.0'
    }
    params = {
        'q': query
    }
    return fetch_reddit_data(url, headers, params)

def sort_reddit_posts(data, key):
    """
    Sort Reddit posts based on the given key (highest voted/lowest votes).
    
    Args:
        data (dict): The JSON data containing Reddit posts.
        key (str): The sorting key ('highest' or 'lowest').

    Returns:
        list: Sorted list of Reddit posts.
    """
    posts = data.get('data', {}).get('children', []) if isinstance(data, dict) else data
    return sorted(posts, key=lambda x: x.get('data', {}).get('ups'), reverse=(key == 'highest'))

def main():
    # Step 3: Making API Requests for the Front Page
    url = 'https://www.reddit.com/.json'
    headers = {
        'User-Agent': 'Custom User Agent/1.0'
    }
    params = {
        'limit': 100
    }
    
    # Fetching Reddit data for the front page
    reddit_data = fetch_reddit_data(url, headers, params)
    
    # Step 4: Handling Authentication and Errors for Front Page Posts
    if reddit_data:
        # Print Reddit posts for the front page
        while True:
            if print_reddit_posts(reddit_data):
                user_input = input(f"{Fore.CYAN}Enter the number of the post you want to view (1-100), 'search' to search, 'sorting' to sort posts, or 'subreddit' to search for a specific subreddit: ")
                if user_input.lower() == 'search':
                    search_query = input("Enter your search query: ")
                    search_results = search_reddit(search_query)
                    if search_results:
                        reddit_data = search_results
                    else:
                        print(f"{Fore.RED}No results found for the search query.")
                elif user_input.lower() == 'sorting':
                    sorting_key = input("Enter 'highest' to sort by highest voted, 'lowest' to sort by lowest voted: ")
                    reddit_data = sort_reddit_posts(reddit_data, sorting_key.lower())
                elif user_input.lower() == 'subreddit':
                    subreddit_name = input("Enter the name of the subreddit: ")
                    subreddit_url = f"https://www.reddit.com/r/{subreddit_name}/.json"
                    subreddit_data = fetch_reddit_data(subreddit_url, headers)
                    if subreddit_data:
                        reddit_data = subreddit_data
                    else:
                        print(f"{Fore.RED}Failed to fetch data for the subreddit '{subreddit_name}'.")
                elif user_input.isdigit():
                    post_number = int(user_input)
                    if 1 <= post_number <= 100:
                        open_post(reddit_data[post_number - 1]['data']['url'])
                    else:
                        print(f"{Fore.RED}Invalid post number. Please enter a number between 1 and 100.")
                else:
                    print(f"{Fore.RED}Invalid input. Please enter a valid number, 'search', 'sorting', or 'subreddit'.")
            else:
                break
    else:
        print(f"{Fore.RED}Error fetching Reddit data.")

if __name__ == "__main__":
    main()