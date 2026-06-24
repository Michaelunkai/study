from typing import List
from providers.base import SearchResult
from matching.scorer import ConfidenceScorer
from matching.normalizer import QueryNormalizer
from .deduplicator import Deduplicator

class Ranker:
    def __init__(self, normalizer: QueryNormalizer, scorer: ConfidenceScorer):
        self.normalizer = normalizer
        self.scorer = scorer
        self.deduplicator = Deduplicator()

    def rank(self, query: str, results: List[SearchResult], confidence_threshold: int = 50) -> List[SearchResult]:
        deduplicated = self.deduplicator.deduplicate(results)

        scored = []
        for r in deduplicated:
            confidence = self.scorer.score(query, r.title)
            if confidence >= confidence_threshold:
                scored.append((confidence, r))

        scored.sort(key=lambda x: (x[0], x[1].seeders), reverse=True)

        return [r for _, r in scored]
