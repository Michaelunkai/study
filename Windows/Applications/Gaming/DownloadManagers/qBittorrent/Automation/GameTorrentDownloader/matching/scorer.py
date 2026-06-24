import re
from .normalizer import QueryNormalizer
from .game_detector import GameDetector

class ConfidenceScorer:
    def __init__(self, normalizer: QueryNormalizer):
        self.normalizer = normalizer
        self.detector = GameDetector()

    def score(self, query: str, filename: str) -> int:
        score = 0
        query_tokens = self.normalizer.tokenize(query)
        filename_tokens = self.normalizer.tokenize(filename)
        filename_lower = self.normalizer.normalize(filename)

        if not query_tokens:
            return 0

        matched = 0
        for qt in query_tokens:
            for ft in filename_tokens:
                if qt == ft or qt in ft or ft in qt:
                    matched += 1
                    break

        if matched == 0 and len(query_tokens) > 1:
            query_joined = ' '.join(query_tokens)
            if query_joined in filename_lower:
                matched = len(query_tokens)

        if matched == 0:
            return 0

        token_ratio = matched / len(query_tokens)
        score += int(token_ratio * 40)

        query_expansions = self.normalizer.expand(query)
        expansion_full_match = False
        for expansion in query_expansions:
            expansion_tokens = self.normalizer.tokenize(expansion)
            exp_matched = sum(1 for et in expansion_tokens if et in filename_tokens)
            if exp_matched == len(expansion_tokens) and exp_matched > 0:
                exp_ratio = exp_matched / len(query_tokens)
                score += int(exp_ratio * 20)
                expansion_full_match = True
                break

        ordered_match = True
        last_pos = -1
        for qt in query_tokens:
            found = False
            for i, ft in enumerate(filename_tokens):
                if i > last_pos and (qt == ft or qt in ft or ft in qt):
                    last_pos = i
                    found = True
                    break
            if not found:
                ordered_match = False
                break
        if ordered_match:
            score += 15

        extra_words = len(filename_tokens) - matched
        penalty = min(extra_words * 2, 20)
        score -= penalty

        movie_count = sum(1 for s in ['1080p','720p','2160p','web-dl','bluray','x264','h265'] if s in filename_lower)
        if movie_count >= 3:
            score -= 30

        music_count = sum(1 for s in ['flac','mp3','album','tracks'] if s in filename_lower)
        if music_count >= 2:
            score -= 25

        version_match_q = re.search(r'v(\d+\.\d+)', query.lower())
        version_match_f = re.search(r'v(\d+\.\d+)', filename.lower())
        if version_match_q and version_match_f:
            if version_match_q.group(1) != version_match_f.group(1):
                score -= 15

        if self.detector.is_game(filename):
            score += 15

        return max(0, min(100, score))
