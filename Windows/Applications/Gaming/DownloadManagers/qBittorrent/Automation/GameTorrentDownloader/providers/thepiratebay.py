# providers/thepiratebay.py
import requests
import re
from typing import List
from .base import SearchProvider, SearchResult

class ThePirateBayProvider(SearchProvider):
    name = "thepiratebay"
    API_URLS = [
        "https://apibay.org/q.php",
        "https://api.thepirat3bay.red/api.php",
    ]

    def is_available(self) -> bool:
        for url in self.API_URLS:
            try:
                r = requests.get(url, params={"q": "test", "cat": "0"}, timeout=5)
                if r.status_code == 200:
                    return True
            except:
                continue
        return False

    def search(self, query: str) -> List[SearchResult]:
        results = []
        for api_url in self.API_URLS:
            try:
                r = requests.get(api_url, params={"q": query, "cat": "0"}, timeout=self.timeout)
                if r.status_code != 200:
                    continue
                data = r.json()
                if not isinstance(data, list):
                    continue
                for item in data:
                    name = item.get('name', '')
                    if not name or name.startswith('No results'):
                        continue
                    info_hash = item.get('info_hash', '').lower()
                    seeders = int(item.get('seeders', 0))
                    leechers = int(item.get('leechers', 0))
                    size_bytes = int(item.get('size', 0))
                    size_gb = size_bytes / (1024**3)
                    magnet = f"magnet:?xt=urn:btih:{info_hash}&dn={requests.utils.quote(name)}"
                    if name and info_hash:
                        results.append(SearchResult(
                            title=name,
                            url=magnet,
                            seeders=seeders,
                            leechers=leechers,
                            size_gb=size_gb,
                            source="thepiratebay",
                            info_hash=info_hash
                        ))
                if results:
                    break
            except Exception as e:
                print(f"  TPB error ({api_url}): {e}")
                continue
        return results
