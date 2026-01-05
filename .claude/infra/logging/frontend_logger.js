/**
 * ============================================================================
 * FRONTEND LOGGER - TovPlay Production
 * ============================================================================
 * Structured logging for React frontend with correlation ID support
 * Integrates with backend logging via correlation IDs
 * Sends logs to backend for centralized collection
 *
 * Features:
 * - Correlation IDs to trace frontend → backend requests
 * - User context tracking
 * - Error boundary integration
 * - Performance tracking
 * - Automatic exception reporting
 * - Session replay context
 *
 * Deploy:
 * Place in: tovplay-frontend/src/utils/logger.js
 * Import: import logger from '@/utils/logger'
 * Usage: logger.info('User clicked button', { buttonId: 'submit' })
 * ============================================================================
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
  // Backend logging endpoint
  endpoint: import.meta.env.VITE_BACKEND_URL + '/api/logs',

  // Log level (DEBUG, INFO, WARN, ERROR)
  level: import.meta.env.VITE_LOG_LEVEL || 'INFO',

  // Enable/disable console logging
  console: import.meta.env.VITE_LOG_CONSOLE !== 'false',

  // Enable/disable backend shipping
  ship: import.meta.env.VITE_LOG_SHIP !== 'false',

  // Batch logs before sending
  batchSize: 10,
  batchTimeout: 5000, // ms

  // Sample rate (0.0 to 1.0)
  sampleRate: parseFloat(import.meta.env.VITE_LOG_SAMPLE_RATE || '1.0'),
};

// Log levels
const LEVELS = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
};

// ============================================================================
// CORRELATION ID MANAGEMENT
// ============================================================================

let currentCorrelationId = null;

/**
 * Generate a unique correlation ID
 */
function generateCorrelationId() {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Get current correlation ID
 */
export function getCorrelationId() {
  if (!currentCorrelationId) {
    currentCorrelationId = generateCorrelationId();
  }
  return currentCorrelationId;
}

/**
 * Set correlation ID (from backend response)
 */
export function setCorrelationId(id) {
  currentCorrelationId = id;
}

/**
 * Clear correlation ID (after request completes)
 */
export function clearCorrelationId() {
  currentCorrelationId = null;
}

// ============================================================================
// USER CONTEXT
// ============================================================================

let userContext = {};

/**
 * Set user context for logging
 */
export function setUserContext(user) {
  userContext = {
    user_id: user?.id,
    username: user?.username,
    email: user?.email,
  };
}

/**
 * Clear user context
 */
export function clearUserContext() {
  userContext = {};
}

// ============================================================================
// LOG BATCHING
// ============================================================================

let logBatch = [];
let batchTimer = null;

/**
 * Add log to batch
 */
function addToBatch(logEntry) {
  logBatch.push(logEntry);

  // Send batch if size limit reached
  if (logBatch.length >= CONFIG.batchSize) {
    flushLogs();
  }

  // Start timer if not already running
  if (!batchTimer) {
    batchTimer = setTimeout(flushLogs, CONFIG.batchTimeout);
  }
}

/**
 * Flush logs to backend
 */
function flushLogs() {
  if (logBatch.length === 0) return;

  const logsToSend = [...logBatch];
  logBatch = [];

  if (batchTimer) {
    clearTimeout(batchTimer);
    batchTimer = null;
  }

  // Send to backend
  if (CONFIG.ship) {
    fetch(CONFIG.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ logs: logsToSend }),
      // Don't wait for response
      keepalive: true,
    }).catch((error) => {
      console.error('Failed to ship logs to backend:', error);
    });
  }
}

// Flush logs before page unload
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', flushLogs);
}

// ============================================================================
// LOGGER CLASS
// ============================================================================

class Logger {
  constructor(name) {
    this.name = name;
  }

  /**
   * Log message
   */
  log(level, message, data = {}) {
    // Check log level
    if (LEVELS[level] < LEVELS[CONFIG.level]) {
      return;
    }

    // Apply sampling (skip if random > sample rate)
    if (Math.random() > CONFIG.sampleRate) {
      return;
    }

    // Build log entry
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      logger: this.name,
      message,
      correlation_id: getCorrelationId(),
      ...userContext,
      ...data,
      // Browser context
      user_agent: navigator.userAgent,
      url: window.location.href,
      referrer: document.referrer || null,
      viewport: {
        width: window.innerWidth,
        height: window.innerHeight,
      },
      // Performance context (if available)
      performance: this._getPerformanceContext(),
    };

    // Console output
    if (CONFIG.console) {
      const consoleMethod = level.toLowerCase();
      console[consoleMethod](`[${level}] ${this.name}:`, message, data);
    }

    // Add to batch
    addToBatch(logEntry);
  }

  /**
   * Get performance context
   */
  _getPerformanceContext() {
    if (!window.performance) return null;

    const navigation = performance.getEntriesByType('navigation')[0];
    if (!navigation) return null;

    return {
      load_time: navigation.loadEventEnd - navigation.fetchStart,
      dom_ready: navigation.domContentLoadedEventEnd - navigation.fetchStart,
      memory: performance.memory ? {
        used: performance.memory.usedJSHeapSize,
        total: performance.memory.totalJSHeapSize,
      } : null,
    };
  }

  /**
   * Debug log
   */
  debug(message, data) {
    this.log('DEBUG', message, data);
  }

  /**
   * Info log
   */
  info(message, data) {
    this.log('INFO', message, data);
  }

  /**
   * Warning log
   */
  warn(message, data) {
    this.log('WARN', message, data);
  }

  /**
   * Error log
   */
  error(message, data) {
    this.log('ERROR', message, data);
  }

  /**
   * Log exception
   */
  exception(error, context = {}) {
    this.error(error.message || 'Unknown error', {
      error_name: error.name,
      error_message: error.message,
      error_stack: error.stack,
      ...context,
    });
  }

  /**
   * Log performance metric
   */
  performance(name, duration, data = {}) {
    this.info(`Performance: ${name}`, {
      performance_metric: name,
      duration_ms: duration,
      ...data,
    });
  }

  /**
   * Log user action
   */
  action(action, data = {}) {
    this.info(`User action: ${action}`, {
      action,
      ...data,
    });
  }
}

// ============================================================================
// FACTORY FUNCTION
// ============================================================================

/**
 * Get logger instance
 */
export function getLogger(name) {
  return new Logger(name);
}

// Default logger
const logger = new Logger('app');

// ============================================================================
// AXIOS INTERCEPTORS (for correlation IDs)
// ============================================================================

/**
 * Setup Axios interceptors to add correlation IDs
 */
export function setupAxiosInterceptors(axios) {
  // Request interceptor - add correlation ID
  axios.interceptors.request.use(
    (config) => {
      const correlationId = getCorrelationId();
      config.headers['X-Correlation-ID'] = correlationId;
      return config;
    },
    (error) => {
      logger.error('Request interceptor error', { error: error.message });
      return Promise.reject(error);
    }
  );

  // Response interceptor - extract correlation ID
  axios.interceptors.response.use(
    (response) => {
      const correlationId = response.headers['x-correlation-id'];
      if (correlationId) {
        setCorrelationId(correlationId);
      }
      return response;
    },
    (error) => {
      logger.error('API request failed', {
        method: error.config?.method,
        url: error.config?.url,
        status: error.response?.status,
        error_message: error.message,
      });
      return Promise.reject(error);
    }
  );
}

// ============================================================================
// REACT ERROR BOUNDARY INTEGRATION
// ============================================================================

/**
 * Error boundary error handler
 */
export function logErrorBoundary(error, errorInfo) {
  logger.exception(error, {
    component_stack: errorInfo.componentStack,
    error_boundary: true,
  });
}

// ============================================================================
// PERFORMANCE TRACKING
// ============================================================================

/**
 * Track component render time
 */
export function trackRender(componentName, startTime) {
  const duration = performance.now() - startTime;
  if (duration > 100) { // Only log slow renders
    logger.performance(`Render: ${componentName}`, duration);
  }
}

/**
 * Track API call duration
 */
export function trackApiCall(method, url, startTime, success) {
  const duration = performance.now() - startTime;
  logger.performance(`API: ${method} ${url}`, duration, {
    success,
    method,
    url,
  });
}

// ============================================================================
// REACT HOOKS
// ============================================================================

/**
 * React hook for logging
 */
export function useLogger(name) {
  return getLogger(name);
}

/**
 * React hook for performance tracking
 */
export function usePerformanceTracking(componentName) {
  const startTime = performance.now();

  return () => {
    trackRender(componentName, startTime);
  };
}

// ============================================================================
// EXPORTS
// ============================================================================

export default logger;

export {
  getLogger,
  setUserContext,
  clearUserContext,
  getCorrelationId,
  setCorrelationId,
  clearCorrelationId,
  setupAxiosInterceptors,
  logErrorBoundary,
  trackRender,
  trackApiCall,
  useLogger,
  usePerformanceTracking,
  flushLogs,
};

// ============================================================================
// EXAMPLE USAGE
// ============================================================================

/*
// 1. Setup in main.jsx
import logger, { setUserContext, setupAxiosInterceptors } from '@/utils/logger';
import axios from 'axios';

// Setup Axios
setupAxiosInterceptors(axios);

// Set user context after login
setUserContext({
  id: 123,
  username: 'john_doe',
  email: 'john@example.com'
});

// 2. Use in components
import { useLogger } from '@/utils/logger';

function MyComponent() {
  const logger = useLogger('MyComponent');

  const handleClick = () => {
    logger.action('button_click', { button_id: 'submit' });
  };

  return <button onClick={handleClick}>Submit</button>;
}

// 3. Use in error boundary
import { logErrorBoundary } from '@/utils/logger';

class ErrorBoundary extends React.Component {
  componentDidCatch(error, errorInfo) {
    logErrorBoundary(error, errorInfo);
  }
}

// 4. Track API calls
import { trackApiCall } from '@/utils/logger';

async function fetchData() {
  const startTime = performance.now();
  try {
    const response = await axios.get('/api/data');
    trackApiCall('GET', '/api/data', startTime, true);
    return response.data;
  } catch (error) {
    trackApiCall('GET', '/api/data', startTime, false);
    throw error;
  }
}

// 5. Track component performance
import { usePerformanceTracking } from '@/utils/logger';

function SlowComponent() {
  const trackPerformance = usePerformanceTracking('SlowComponent');

  useEffect(() => {
    return trackPerformance;
  }, []);

  // ... component logic
}
*/
