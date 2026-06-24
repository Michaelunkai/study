import re

EDITION_MAP = {
    "goty": "game of the year edition",
    "deluxe": "deluxe edition",
    "ultimate": "ultimate edition",
    "complete": "complete edition",
    "premium": "premium edition",
    "gold": "gold edition",
    "definitive": "definitive edition",
    "enhanced": "enhanced edition",
    "directors cut": "directors cut",
    "game of the year": "game of the year",
}

PLATFORM_STRIP = {"pc", "win", "windows", "steam", "epic", "gog", "origin", "uplay", "rockstar", "r星"}

class QueryNormalizer:
    def __init__(self, aliases: dict):
        self.aliases = aliases
        self._build_reverse_aliases()

    def _build_reverse_aliases(self):
        self.reverse_aliases = {}
        for canonical, alias_list in self.aliases.items():
            for alias in alias_list:
                key = alias.lower().strip()
                if key not in self.reverse_aliases:
                    self.reverse_aliases[key] = canonical.lower().strip()

    def normalize(self, text: str) -> str:
        text = text.lower().strip()
        text = re.sub(r'[^\w\s]', ' ', text)
        text = re.sub(r'\s+', ' ', text).strip()
        return text

    def tokenize(self, text: str) -> list:
        text = self.normalize(text)
        tokens = text.split()
        tokens = [t for t in tokens if not re.match(r'^v?\d+\.\d+(\.\d+)?$', t)]
        return tokens

    def normalize_edition(self, text: str) -> str:
        text_lower = text.lower().strip()
        for key, val in EDITION_MAP.items():
            if key in text_lower:
                return val
        return text_lower

    def expand(self, query: str) -> list:
        query_norm = self.normalize(query)
        expansions = [query_norm]

        for alias_key, canonical in self.reverse_aliases.items():
            if alias_key == query_norm or query_norm in alias_key.split():
                canonical_entry = self.aliases.get(canonical, self.aliases.get(query_norm, []))
                for a in canonical_entry:
                    a_norm = self.normalize(a)
                    if a_norm not in expansions:
                        expansions.append(a_norm)

        for canonical, alias_list in self.aliases.items():
            canonical_norm = self.normalize(canonical)
            if canonical_norm == query_norm:
                for a in alias_list:
                    a_norm = self.normalize(a)
                    if a_norm not in expansions:
                        expansions.append(a_norm)
            for a in alias_list:
                if self.normalize(a) == query_norm:
                    if canonical_norm not in expansions:
                        expansions.append(canonical_norm)
                    for a2 in alias_list:
                        a2_norm = self.normalize(a2)
                        if a2_norm not in expansions:
                            expansions.append(a2_norm)

        return expansions