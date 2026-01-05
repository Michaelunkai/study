import { createContext, useState, useEffect, useCallback } from "react";
import { translations } from "./translations";

// Create the context
export const LanguageContext = createContext();

// Locale configurations
const localeConfigs = {
  en: {
    code: 'en',
    direction: 'ltr',
    locale: 'en-US'
  },
  he: {
    code: 'he',
    direction: 'rtl',
    locale: 'he-IL'
  }
};

const getInitialLanguage = () => {
  if (typeof window !== "undefined") {
    return localStorage.getItem("tovplay-lang") || "en";
  }
  return "en";
};

const LanguageProvider = ({ children }) => {
  const [language, setLanguage] = useState(getInitialLanguage);
  
  const [locale, setLocale] = useState(localeConfigs[language] || localeConfigs.en);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const newLocale = localeConfigs[language] || localeConfigs.en;
      setLocale(newLocale);
      localStorage.setItem("tovplay-lang", language);
      document.documentElement.lang = language;
      document.documentElement.dir = newLocale.direction;
    }
  }, [language]);

  const t = useCallback((key, defaultText) => {
    // If no key is provided, return the default text or empty string
    if (!key) return defaultText || '';
    
    // Handle nested keys (e.g., 'profile.title')
    const keys = key.split('.');
    let result = keys.reduce((obj, k) => {
      return (obj && obj[k] !== undefined) ? obj[k] : undefined;
    }, translations[language]);
    
    // Fallback to English if translation not found in current language
    if (result === undefined) {
      result = keys.reduce((obj, k) => {
        return (obj && obj[k] !== undefined) ? obj[k] : undefined;
      }, translations['en']);
    }
    
    // If still not found, return the default text or the last part of the key
    if (result === undefined) {
      return defaultText || keys[keys.length - 1];
    }
    
    // If we have a string result, handle any replacements
    if (typeof result === 'string') {
      // Handle simple variable replacements like {name}
      if (typeof defaultText === 'object') {
        return Object.entries(defaultText).reduce(
          (str, [k, v]) => str.replace(new RegExp(`\\{${k}\\}`, 'g'), v),
          result
        );
      }
      return result;
    }
    
    return result || defaultText || keys[keys.length - 1];
  }, [language]);

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t, locale }}>
      {children}
    </LanguageContext.Provider>
  );
};

export { LanguageProvider };
export default LanguageProvider;
