import axios from "axios";

axios.defaults.baseURL = import.meta.env.VITE_API_BASE_URL || "http://localhost:5000";
axios.defaults.timeout = parseInt(import.meta.env.VITE_API_TIMEOUT) || 10000;

export default axios;
