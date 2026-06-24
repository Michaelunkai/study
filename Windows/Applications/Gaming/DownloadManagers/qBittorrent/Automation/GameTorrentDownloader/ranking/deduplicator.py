from typing import List, Dict
from providers.base import SearchResult

class Deduplicator:
    def deduplicate(self, results: List[SearchResult]) -> List[SearchResult]:
        seen: Dict[str, SearchResult] = {}
        for r in results:
            key = r.info_hash if r.info_hash else r.url
            if key in seen:
                existing = seen[key]
                if r.seeders > existing.seeders:
                    seen[key] = r
            else:
                seen[key] = r
        return list(seen.values())
