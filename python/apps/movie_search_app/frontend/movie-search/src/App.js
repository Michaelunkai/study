import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Movie from './Movie';
import './App.css'; // Importing styles

const App = () => {
    const [movies, setMovies] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [filteredMovies, setFilteredMovies] = useState([]);

    useEffect(() => {
        axios.get(`http://www.omdbapi.com/?apikey=4b4d3482&s=${searchTerm}`)
            .then(response => {
                if (response.data.Search) {
                    setMovies(response.data.Search);
                }
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
    }, [searchTerm]);

    useEffect(() => {
        const filtered = movies.filter(movie =>
            movie.Title.toLowerCase().includes(searchTerm.toLowerCase())
        );
        setFilteredMovies(filtered);
    }, [movies, searchTerm]);

    const handleSearch = (e) => {
        setSearchTerm(e.target.value);
    };

    return (
        <div className="App"> {/* Using the 'App' class */}
            <h1>Movie Search App</h1>
            <input
                type="text"
                placeholder="Search..." 
                value={searchTerm}
                onChange={handleSearch} // Removing curly braces around comment
            />
            <div>
                {filteredMovies.map((movie, index) => (
                    <Movie
                        key={index}
                        title={movie.Title}
                        year={movie.Year}
                        genre={movie.Genre}
                        plot={movie.Plot}
                    />
                ))}
            </div>
        </div>
    );
}

export default App;

