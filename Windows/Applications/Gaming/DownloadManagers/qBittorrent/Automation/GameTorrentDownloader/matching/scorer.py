import re
from .normalizer import QueryNormalizer
from .game_detector import GameDetector


class ConfidenceScorer:
    def __init__(self, normalizer: QueryNormalizer):
        self.normalizer = normalizer
        self.detector = GameDetector()

    def score(self, query: str, filename: str) -> int:
        query_tokens_raw = self.normalizer.tokenize(query)
        filename_tokens_raw = self.normalizer.tokenize(filename)
        filename_lower = self.normalizer.normalize(filename)

        if not query_tokens_raw:
            return 0

        if self.detector.is_definitely_not_game(filename):
            return 0

        query_tokens_rom = self.normalizer.tokenize_with_roman(query)
        filename_tokens_rom = self.normalizer.tokenize_with_roman(filename)

        direct_matched = 0
        direct_positions = []
        for qt in query_tokens_rom:
            best_pos = -1
            for i, ft in enumerate(filename_tokens_rom):
                if i in direct_positions:
                    continue
                if qt == ft:
                    best_pos = i
                    break
            if best_pos >= 0:
                direct_matched += 1
                direct_positions.append(best_pos)

        if direct_matched == 0:
            query_as_phrase = ' '.join(query_tokens_rom)
            phrase_positions = self._find_phrase(filename_lower, query_as_phrase)
            if phrase_positions is not None:
                direct_matched = len(query_tokens_raw)

        expansion_matched = False
        expansion_match_count = 0
        query_expansions = self.normalizer.expand(query)
        for expansion in query_expansions:
            expansion_tokens_rom = self.normalizer.tokenize_with_roman(expansion)
            expansion_tokens_raw = self.normalizer.tokenize(expansion)

            exp_positions_rom = []
            exp_matched_rom = 0
            for et in expansion_tokens_rom:
                for i, ft in enumerate(filename_tokens_rom):
                    if i not in exp_positions_rom and et == ft:
                        exp_positions_rom.append(i)
                        exp_matched_rom += 1
                        break
            if exp_matched_rom == len(expansion_tokens_rom) and exp_matched_rom > 0:
                expansion_matched = True
                expansion_match_count = exp_matched_rom
                break

            exp_positions_raw = []
            exp_matched_raw = 0
            for et in expansion_tokens_raw:
                for i, ft in enumerate(filename_tokens_raw):
                    if i not in exp_positions_raw and et == ft:
                        exp_positions_raw.append(i)
                        exp_matched_raw += 1
                        break
            if exp_matched_raw == len(expansion_tokens_raw) and exp_matched_raw > 0:
                expansion_matched = True
                expansion_match_count = exp_matched_raw
                break

        if direct_matched == 0 and not expansion_matched:
            return 0

        effective_match = max(direct_matched, expansion_match_count)
        total_tokens = len(query_tokens_raw)
        all_tokens_matched = effective_match >= total_tokens
        token_ratio = effective_match / total_tokens

        if all_tokens_matched:
            score = 65
        elif token_ratio >= 0.5:
            score = 40
        else:
            score = 0

        if score == 0:
            return 0

        if expansion_matched:
            score += 15

        ordered_match = True
        last_pos = -1
        for qt in query_tokens_rom:
            found = False
            for i, ft in enumerate(filename_tokens_rom):
                if i > last_pos and qt == ft:
                    last_pos = i
                    found = True
                    break
            if not found:
                ordered_match = False
                break
        if ordered_match:
            score += 10

        extra_words = len(filename_tokens_raw) - effective_match
        if extra_words > 0 and not all_tokens_matched:
            penalty = min(extra_words * 3, 20)
            score -= penalty

        movie_count = sum(1 for s in ['1080p','720p','2160p','web-dl','bluray','x264','x265','h264','h265','dvdrip','webrip','bdrip','brrip','hevc','remux','xvid','hdtv'] if s in filename_lower)
        if movie_count >= 1:
            score -= 50

        year_match = re.search(r'[\.\s\[\(]((?:19|20)\d{2})[\.\s\]\)]', filename_lower)
        if year_match:
            score -= 40

        if all_tokens_matched:
            has_game_group = any(g in filename_lower for g in ['fitgirl','dodi','tenoke','reloaded','kaos','empress','elamigos','razor1911','codex','cpy','skidrow','plaza','corepack','rune','mercs','rgmechanics','mechanics','chronos'])
            if has_game_group:
                score += 15

            has_edition = any(e in filename_lower for e in ['goty','deluxe','ultimate','dlc','complete','premium','definitive','enhanced','collection','anthology','digital deluxe'])
            if has_edition:
                score += 5

            has_platform = any(p in filename_lower for p in ['pc game','pc dvd','pc iso','steam','gog','epic','origin','windows','game','repack','steamrip'])
            if has_platform:
                score += 5

            size_match = re.search(r'(\d+\.?\d*)\s*(gb|mb|tb)', filename_lower)
            if size_match:
                size_val = float(size_match.group(1))
                size_unit = size_match.group(2)
                if size_unit == 'gb' and size_val >= 1.0:
                    score += 5

        version_match_q = re.search(r'v(\d+\.\d+)', query.lower())
        version_match_f = re.search(r'v(\d+\.\d+)', filename.lower())
        if version_match_q and version_match_f:
            if version_match_q.group(1) != version_match_f.group(1):
                score -= 20

        if all_tokens_matched and self.detector.is_game(filename):
            score += 10

        return max(0, min(100, score))

    def _find_phrase(self, text: str, phrase: str) -> tuple:
        pattern = re.compile(r'\b' + re.escape(phrase) + r'\b')
        m = pattern.search(text)
        if m:
            return (m.start(), m.end())
        return None
