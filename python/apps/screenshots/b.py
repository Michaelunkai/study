import requests
from bs4 import BeautifulSoup

def get_gamespot_rating(game_name):
    base_url = "https://www.gamespot.com"
    search_url = f"{base_url}/search/?q={game_name.replace(' ', '+')}"

    response = requests.get(search_url)
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find the search results
    search_results = soup.find_all('a', class_='card-item')

    if not search_results:
        return f"No results found for '{game_name}'", []

    # Extract titles and links of search results
    similar_titles = []
    for result in search_results:
        title = result.find('h3').get_text(strip=True)
        link = result['href']
        similar_titles.append((title, link))

    # Fetch the first game's details page
    first_result = similar_titles[0]
    game_url = first_result[1]
    game_page_url = f"{base_url}{game_url}"
    game_response = requests.get(game_page_url)
    game_soup = BeautifulSoup(game_response.text, 'html.parser')

    # Find the rating
    rating_tag = game_soup.find('div', class_='gs-score__cell')
    if rating_tag:
        rating = rating_tag.get_text(strip=True)
        return f"The rating for '{first_result[0]}' is {rating}", []

    return f"No exact match found for '{game_name}'", [title for title, _ in similar_titles]

def main():
    game_name = input("Enter the game name: ")
    rating_message, similar_titles = get_gamespot_rating(game_name)

    print(rating_message)
    if similar_titles:
        print("Did you mean one of these titles?")
        for title in similar_titles:
            print(f"- {title}")

if __name__ == "__main__":
    main()
