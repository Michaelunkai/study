import requests
from typing import List
from .base import SearchProvider, SearchResult

class JackettProvider(SearchProvider):
    name = "jackett"

    def __init__(self, config: dict):
        super().__init__(config)
        jackett_config = config.get('jackett', {})
        self.base_url = jackett_config.get('url', 'http://127.0.0.1:9117')
        self.api_key = jackett_config.get('api_key', '')
        self.auto_discover = jackett_config.get('auto_discover', True)

    def is_available(self) -> bool:
        try:
            url = f"{self.base_url}/api/v2.0/indexers/all/results"
            params = {"q": "test", "Category[]": 4000}
            if self.api_key:
                params["api_key"] = self.api_key
            r = requests.get(url, params=params, timeout=5)
            return r.status_code == 200
        except:
            return False

    def search(self, query: str) -> List[SearchResult]:
        results = []
        try:
            url = f"{self.base_url}/api/v2.0/indexers/all/results"
            params = {"q": query, "Category[]": 4000}
            if self.api_key:
                params["api_key"] = self.api_key
            r = requests.get(url, params=params, timeout=self.timeout)
            if r.status_code != 200:
                return results
            data = r.json()
            for item in data.get('Results', []):
                title = item.get('Title', '')
                seeders = item.get('Seeders', 0)
                leechers = item.get('Peers', 0) - seeders
                size_bytes = item.get('Size', 0)
                size_gb = size_bytes / (1024**3)
                magnet = item.get('MagnetUri', '')
                link = item.get('Link', '')
                url = magnet if magnet else link
                info_hash = item.get('InfoHash', '')
                if not info_hash and magnet:
                    import re
                    m = re.search(r'btih:([a-fA-F0-9]{40})', magnet)
                    if m:
                        info_hash = m.group(1).lower()
                if title and url:
                    results.append(SearchResult(
                        title=title,
                        url=url,
                        seeders=seeders,
                        leechers=max(0, leechers),
                        size_gb=size_gb,
                        source="jackett",
                        info_hash=info_hash
                    ))
        except Exception as e:
            print(f"  Jackett error: {e}")
        return results
