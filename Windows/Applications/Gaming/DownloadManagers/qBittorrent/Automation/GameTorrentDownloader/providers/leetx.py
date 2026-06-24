# providers/leetx.py
import requests
from bs4 import BeautifulSoup
from typing import List
from .base import SearchProvider, SearchResult

class LeetxProvider(SearchProvider):
    name = "1337x"
    BASE_URL = "https://1337x.to"

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
            search_url = f"{self.BASE_URL}/search/{query}/1/"
            r = requests.get(search_url, headers=self._headers(), timeout=self.timeout)
            if r.status_code != 200:
                return results
            soup = BeautifulSoup(r.text, 'html.parser')
            table = soup.find('table', class_='table-list')
            if not table:
                return results
            rows = table.find('tbody').find_all('tr')[:30]
            for row in rows:
                cols = row.find_all('td')
                if len(cols) < 7:
                    continue
                name_tag = cols[0].find('a', class_='name')
                if not name_tag:
                    continue
                title = name_tag.get_text(strip=True)
                detail_link = name_tag.get('href', '')
                seeders = self._parse_int(cols[1].get_text(strip=True))
                leechers = self._parse_int(cols[2].get_text(strip=True))
                size_text = cols[4].get_text(strip=True)
                size_gb = self._parse_size(size_text)
                magnet = self._get_magnet(detail_link)
                if magnet:
                    import re
                    m = re.search(r'btih:([a-fA-F0-9]{40})', magnet)
                    info_hash = m.group(1).lower() if m else ""
                    results.append(SearchResult(
                        title=title,
                        url=magnet,
                        seeders=seeders,
                        leechers=leechers,
                        size_gb=size_gb,
                        source="1337x",
                        info_hash=info_hash
                    ))
        except Exception as e:
            print(f"  1337x error: {e}")
        return results

    def _get_magnet(self, detail_path: str) -> str:
        try:
            url = f"{self.BASE_URL}{detail_path}"
            r = requests.get(url, headers=self._headers(), timeout=self.timeout)
            soup = BeautifulSoup(r.text, 'html.parser')
            magnet_link = soup.find('a', href=lambda x: x and x.startswith('magnet:'))
            return magnet_link['href'] if magnet_link else ""
        except:
            return ""

    def _parse_int(self, text: str) -> int:
        try:
            return int(text.replace(',', ''))
        except:
            return 0

    def _parse_size(self, text: str) -> float:
        text = text.lower().strip()
        try:
            if 'gb' in text:
                return float(text.replace('gb', '').strip())
            elif 'mb' in text:
                return float(text.replace('mb', '').strip()) / 1024
            elif 'tb' in text:
                return float(text.replace('tb', '').strip()) * 1024
        except:
            pass
        return 0.0
