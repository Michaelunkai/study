from elasticsearch import Elasticsearch

# Specify the Elasticsearch server's host and port
es = Elasticsearch(["http://localhost:9200"])  # Assuming Elasticsearch is running on localhost with port 9200

def search_movies(query):
    # search movies using the Elasticsearch `search` method
    # and return the search results
    res = es.search(index="movies", body=query)
    return res

def filter_movies(name=None, actors=None, genre=None, date=None):
    # create a bool query to filter the movies
    bool_query = {
        "bool": {
            "must": []
        }
    }
    # add filters to the bool query based on the provided parameters
    if name:
        bool_query["bool"]["must"].append({"match": {"name": name}})
    if actors:
        bool_query["bool"]["must"].append({"match": {"actors": actors}})
    if genre:
        bool_query["bool"]["must"].append({"match": {"genre": genre}})
    if date:
        bool_query["bool"]["must"].append({"match": {"release_date": date}})
    # create the Elasticsearch query
    query = {
        "query": bool_query
    }
    # search and return the movies
    return search_movies(query)

# Example usage:
# res = filter_movies(name="The Matrix")
# print(res)
