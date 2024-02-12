import React, { useState } from "react";
import axios from "axios";

const MovieSearch = () => {
  const [query, setQuery] = useState("");
  const [movies, setMovies] = useState([]);

  const searchMovies = () => {
    axios
      .get("http://localhost:5000/search", {
        params: {
          q: query
        }
      })
      .then(res => {
        setMovies(res.data.hits.hits);
      });
  };

  const filterMovies = () => {
    axios
      .post("http://localhost:5000/filter", {
        name: query,
        actors: query,
        genre: query,
        date: query
      })
      .then(res => {
        setMovies(res.data.hits.hits);
      });
  };

  const handleKeyPress = event => {
    if (event.key === "Enter") {
      if (query) {
        filterMovies();
      } else {
        setMovies([]);
      }
    }
  };

  return (
    <div>
      <input
        type="text"
        value={query}
        onChange={event => setQuery(event.target.value)}
        onKeyPress={handleKeyPress}
      />
      <button onClick={searchMovies}>Search</button>
      {movies.map(movie => (
        <div key={movie._id}>
          <img src={movie.poster_url} alt={movie._source.name} />
          <h2>{movie._source.name}</h2>
          <p>Actors: {movie._source.actors}</p>
          <p>Genre: {movie._source.genre}</p>
          <p>Release Date: {movie._source.release_date}</p>
        </div>
      ))}
    </div>
  );
};

export default MovieSearch;
