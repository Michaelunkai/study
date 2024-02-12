import React from 'react';

const Movie = ({ title, year, genre, plot }) => { // Step 12: Accepting additional props
    return (
        <div className="movie"> {/* Step 10: Adding movie class */}
            <h3>{title}</h3>
            <p>Year: {year}</p> {/* Step 12: Displaying more movie details */}
            <p>Genre: {genre}</p> {/* Step 12: Displaying more movie details */}
            <p>Plot: {plot}</p> {/* Step 12: Displaying more movie details */}
        </div>
    );
}

export default Movie;
