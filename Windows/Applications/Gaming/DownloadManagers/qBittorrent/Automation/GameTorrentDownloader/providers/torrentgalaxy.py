# providers/torrentgalaxy.py
import requests
from bs4 import BeautifulSoup
from typing import List
from .base import SearchProvider, SearchResult

class TorrentGalaxyProvider(SearchProvider):
    name = "torrentgalaxy"
    BASE_URL = "https://torrentgalaxy.to"

    def is_available(self) -> bool:
        try:
            r = requests.get(self.BASE_URL, timeout=5, headers=self._headers())
            return r.status_code == 200
        except:
            return False

    def _headers(self):
        return {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

    def search(self, query: str) -> List[SearchResult]:
        results = []
        try:
            url = f"{self.BASE_URL}/torrents.php"
            params = {"search": query, "sort": "seeders", "order": "desc"}
            r = requests.get(url, params=params, headers=self._headers(), timeout=self.timeout)
            if r.status_code != 200:
                return results
            soup = BeautifulSoup(r.text, 'html.parser')
            rows = soup.select('div.tgxtablerow.txlight')
            for row in rows[:30]:
                cols = row.select('div.tgxtablecell')
                if len(cols) < 8:
                    continue
                title_tag = cols[1].find('a', title=True)
                if not title_tag:
                    continue
                title = title_tag.get('title', title_tag.get_text(strip=True))
                seeders = self._parse_int(cols[5].get_text(strip=True))
                leechers = self._parse_int(cols[6].get_text(strip=True))
                size_text = cols[7].get_text(strip=True)
                size_gb = self._parse_size(size_text)
                magnet_tag = row.find('a', href=lambda x: x and x.startswith('magnet:'))
                magnet = magnet_tag['href'] if magnet_tag else ""
                if not magnet:
                    continue
                import re
                m = re.search(r'btih:([a-fA-F0-9]{40})', magnet)
                info_hash = m.group(1).lower() if m else ""
                results.append(SearchResult(
                    title=title,
                    url=magnet,
                    seeders=seeders,
                    leechers=leechers,
                    size_gb=size_gb,
                    source="torrentgalaxy",
                    info_hash=info_hash
                ))
        except Exception as e:
            print(f"  TorrentGalaxy error: {e}")
        return results

    def _parse_int(self, text: str) -> int:
        try:
            return int(text.replace(',', '').replace('.', ''))
        except:
            return 0

    def _parse_size(self, text: str) -> float:
        text = text.lower().strip()
        try:
            if 'gb' in text:
                return float(''.join(c for c in text.split('gb')[0] if c.isdigit() or c == '.'))
            elif 'mb' in text:
                return float(''.join(c for c in text.split('mb')[0] if c.isdigit() or c == '.')) / 1024
            elif 'tb' in text:
                return float(''.join(c for c in text.split('tb')[0] if c.isdigit() or c == '.')) * 1024
        except:
            pass
        return 0.0
