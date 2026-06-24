# providers/prowlarr.py
import requests
import re
from typing import List
from .base import SearchProvider, SearchResult

class ProwlarrProvider(SearchProvider):
    name = "prowlarr"

    def __init__(self, config: dict):
        super().__init__(config)
        prowlarr_config = config.get('prowlarr', {})
        self.base_url = prowlarr_config.get('url', 'http://127.0.0.1:9696')
        self.api_key = prowlarr_config.get('api_key', '')
        self.auto_discover = prowlarr_config.get('auto_discover', True)

    def is_available(self) -> bool:
        try:
            url = f"{self.base_url}/api/v1/search"
            params = {"query": "test", "type": "search"}
            if self.api_key:
                params["apikey"] = self.api_key
            r = requests.get(url, params=params, timeout=5)
            return r.status_code in (200, 400)
        except:
            return False

    def search(self, query: str) -> List[SearchResult]:
        results = []
        try:
            url = f"{self.base_url}/api/v1/search"
            params = {"query": query, "type": "search"}
            if self.api_key:
                params["apikey"] = self.api_key
            r = requests.get(url, params=params, timeout=self.timeout)
            if r.status_code != 200:
                return results
            data = r.json()
            if not isinstance(data, list):
                return results
            for item in data:
                title = item.get('title', '')
                seeders = item.get('seeders', 0)
                leechers = item.get('leechers', 0)
                size = item.get('size', 0)
                size_gb = size / (1024**3)
                magnet = item.get('magnetUrl', '')
                link = item.get('link', '')
                url = magnet if magnet else link
                info_hash = item.get('infoHash', '')
                if not info_hash and magnet:
                    m = re.search(r'btih:([a-fA-F0-9]{40})', magnet)
                    if m:
                        info_hash = m.group(1).lower()
                if title and url:
                    results.append(SearchResult(
                        title=title,
                        url=url,
                        seeders=seeders,
                        leechers=leechers,
                        size_gb=size_gb,
                        source="prowlarr",
                        info_hash=info_hash
                    ))
        except Exception as e:
            print(f"  Prowlarr error: {e}")
        return results
