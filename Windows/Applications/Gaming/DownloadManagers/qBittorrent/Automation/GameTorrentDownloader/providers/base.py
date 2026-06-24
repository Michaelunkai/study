from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class SearchResult:
    title: str
    url: str
    seeders: int
    leechers: int
    size_gb: float
    source: str
    info_hash: str

    @property
    def is_magnet(self) -> bool:
        return self.url.startswith('magnet:')

class SearchProvider:
    name: str = "base"

    def __init__(self, config: dict):
        self.config = config
        self.timeout = config.get('search', {}).get('timeout_per_source', 15)

    def search(self, query: str) -> List[SearchResult]:
        raise NotImplementedError

    def is_available(self) -> bool:
        raise NotImplementedError
