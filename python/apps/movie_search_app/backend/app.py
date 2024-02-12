from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/api/movies')
def get_movies():
    # Placeholder code to return sample movie data
    movies = [{'title': 'Movie 1'}, {'title': 'Movie 2'}]
    return jsonify(movies)

if __name__ == '__main__':
    app.run(debug=True)
