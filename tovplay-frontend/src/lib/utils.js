import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs) {
  return twMerge(clsx(inputs));
} 

// Simple function to create a delay promise
//
// Usage: await delay(1000); // delays for 1 second
// Returns a Promise that resolves after the specified milliseconds
// @param {number} ms - Milliseconds to delay
// @returns {Promise<void>}

export function delayPromise(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Simple function to create cancelable delay promise
//
// Usage: await delay(1000); // delays for 1 second
// Returns a Promise that resolves after the specified milliseconds
// @param {number} ms - Milliseconds to delay
// returns {promise: Promise<void>, cancel: function()=>void}

export function cancleableDelayPromise(ms) {
  let timeoutId;
  const promise = new Promise((resolve, reject) => {
    timeoutId = setTimeout(() => {
      resolve();
    }, ms);
  });
  return {
    promise,
    cancel: () => clearTimeout(timeoutId)
  };
}
