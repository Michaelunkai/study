# providers/nyaa.py
import requests
from bs4 import BeautifulSoup
from typing import List
from .base import SearchProvider, SearchResult

class NyaaProvider(SearchProvider):
    name = "nyaa"
    BASE_URL = "https://nyaa.si"

    def is_available(self) -> bool:
        try:
            r = requests.get(self.BASE_URL, timeout=5)
            return r.status_code == 200
        except:
            return False

    def search(self, query: str) -> List[SearchResult]:
        results = []
        try:
            params = {"f": "0", "c": "0_0", "q": query, "s": "seeders", "o": "desc"}
            r = requests.get(self.BASE_URL, params=params, timeout=self.timeout)
            if r.status_code != 200:
                return results
            soup = BeautifulSoup(r.text, 'html.parser')
            table = soup.find('table', class_='table-hover')
            if not table:
                return results
            rows = table.find('tbody').find_all('tr')[:30]
            for row in rows:
                cols = row.find_all('td')
                if len(cols) < 7:
                    continue
                title_tag = cols[1].find('a', title=True)
                if not title_tag:
                    title_tag = cols[1].find('a')
                title = title_tag.get('title', title_tag.get_text(strip=True)) if title_tag else ""
                seeders = self._parse_int(cols[4].get_text(strip=True))
                leechers = self._parse_int(cols[5].get_text(strip=True))
                downloads = self._parse_int(cols[6].get_text(strip=True))
                magnet_tag = cols[2].find('a', href=lambda x: x and x.startswith('magnet:'))
                magnet = magnet_tag['href'] if magnet_tag else ""
                if not magnet:
                    continue
                size_tag = cols[3]
                size_gb = self._parse_size(size_tag.get_text(strip=True))
                import re
                m = re.search(r'btih:([a-fA-F0-9]{40})', magnet)
                info_hash = m.group(1).lower() if m else ""
                results.append(SearchResult(
                    title=title,
                    url=magnet,
                    seeders=seeders,
                    leechers=leechers,
                    size_gb=size_gb,
                    source="nyaa",
                    info_hash=info_hash
                ))
        except Exception as e:
            print(f"  Nyaa error: {e}")
        return results

    def _parse_int(self, text: str) -> int:
        try:
            return int(text.replace(',', ''))
        except:
            return 0

    def _parse_size(self, text: str) -> float:
        text = text.lower().strip()
        try:
            if 'gi' in text:
                return float(text.replace('gi', '').strip())
            elif 'mi' in text:
                return float(text.replace('mi', '').strip()) / 1024
            elif 'ti' in text:
                return float(text.replace('ti', '').strip()) * 1024
        except:
            pass
        return 0.0
