import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from matching.normalizer import QueryNormalizer

def test_basic_normalization():
    q = QueryNormalizer({})
    assert q.normalize("Elden Ring") == "elden ring"

def test_alias_expansion_gta_v():
    aliases = {"gta v": ["gta 5", "grand theft auto v", "grand theft auto 5"]}
    q = QueryNormalizer(aliases)
    expanded = q.expand("GTA V")
    assert "gta 5" in expanded
    assert "grand theft auto v" in expanded
    assert "grand theft auto 5" in expanded

def test_alias_expansion_gta_5():
    aliases = {"gta 5": ["gta v", "grand theft auto 5", "grand theft auto v"]}
    q = QueryNormalizer(aliases)
    expanded = q.expand("GTA 5")
    assert "gta v" in expanded

def test_strips_version_numbers():
    q = QueryNormalizer({})
    tokens = q.tokenize("Game v1.2.3 Enhanced Edition")
    assert "v1.2.3" not in tokens

def test_platform_normalization():
    q = QueryNormalizer({})
    tokens = q.tokenize("Game [PC] [Win] [Windows]")
    assert "pc" in tokens or "win" in tokens or "windows" in tokens

def test_edition_normalization():
    q = QueryNormalizer({})
    assert q.normalize_edition("GOTY Edition") == "game of the year edition"
    assert q.normalize_edition("Deluxe") == "deluxe edition"

if __name__ == "__main__":
    test_basic_normalization()
    test_alias_expansion_gta_v()
    test_alias_expansion_gta_5()
    test_strips_version_numbers()
    test_platform_normalization()
    test_edition_normalization()
    print("All normalizer tests passed!")