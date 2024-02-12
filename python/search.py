from googleapiclient.discovery import build

def google_search(query, api_key, cx):
    service = build('customsearch', 'v1', developerKey=api_key)
    res = service.cse().list(q=query, cx=cx, num=40).execute()  # Set num=40 to retrieve 40 search results
    return res['items']

# Your API Key and Custom Search Engine ID
api_key = 'AIzaSyCkxGb8BRRk6veSR85dViWX6-QMhOAWT1I'
cx = '77de5e8acdee44d44'  # Replace 'YOUR_CUSTOM_SEARCH_ENGINE_ID' with your actual ID

# Prompt the user to enter search words
query = input("Enter your search query: ")

# Perform the search
results = google_search(query, api_key, cx)

# Print search results with improved formatting
print("\nSearch Results:")
print("-" * 50)
for i, result in enumerate(results, start=1):
    print(f"{i}. {result['title']}")
    print(f"   {result['link']}")
    print("-" * 50)
