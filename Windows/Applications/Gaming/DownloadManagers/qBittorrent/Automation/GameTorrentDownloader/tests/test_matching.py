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

from matching.game_detector import GameDetector
from matching.scorer import ConfidenceScorer

def test_fitgirl_is_game():
    d = GameDetector()
    assert d.is_game("Elden.Ring.v1.12.3-FitGirl") == True

def test_movie_not_game():
    d = GameDetector()
    assert d.is_game("Elden.Ring.2022.1080p.WEB-DL.x264-GalaxyRG") == False

def test_tv_not_game():
    d = GameDetector()
    assert d.is_game("Game.of.Thrones.S01E01.720p.BluRay") == False

def test_music_not_game():
    d = GameDetector()
    assert d.is_game("Artist.Album.2024.FLACtracks") == False

def test_iso_is_game():
    d = GameDetector()
    assert d.is_game("Elden.Ring-FLT [28.5 GB].iso") == True

def test_scoring_exact_match():
    s = ConfidenceScorer(QueryNormalizer({}))
    score = s.score("elden ring", "ELDEN.RING.v1.12.3-RUNE")
    assert score >= 60

def test_scoring_partial_match():
    s = ConfidenceScorer(QueryNormalizer({}))
    score = s.score("elden ring", "ELDEN.RING.Shadow.of.the.Erdtree-RUNE")
    assert score >= 50

def test_scoring_no_match():
    s = ConfidenceScorer(QueryNormalizer({}))
    score = s.score("elden ring", "Grand.Theft.Auto.V-PLAZA")
    assert score < 30

def test_scoring_movie_penalty():
    s = ConfidenceScorer(QueryNormalizer({}))
    score = s.score("elden ring", "Elden.Ring.2022.1080p.WEB-DL.x264")
    assert score == 0

if __name__ == "__main__":
    test_basic_normalization()
    test_alias_expansion_gta_v()
    test_alias_expansion_gta_5()
    test_strips_version_numbers()
    test_platform_normalization()
    test_edition_normalization()
    test_fitgirl_is_game()
    test_movie_not_game()
    test_tv_not_game()
    test_music_not_game()
    test_iso_is_game()
    test_scoring_exact_match()
    test_scoring_partial_match()
    test_scoring_no_match()
    test_scoring_movie_penalty()
    print("All detection + scoring tests passed!")