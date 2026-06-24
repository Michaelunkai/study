import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from providers.base import SearchResult

def test_search_result_creation():
    r = SearchResult(
        title="ELDEN.RING.v1.12.3-RUNE",
        url="magnet:?xt=urn:btih:abc123",
        seeders=5234,
        leechers=123,
        size_gb=45.2,
        source="jackett",
        info_hash="abc123"
    )
    assert r.title == "ELDEN.RING.v1.12.3-RUNE"
    assert r.seeders == 5234
    assert r.is_magnet == True

def test_search_result_is_magnet():
    r = SearchResult(title="test", url="https://example.com/torrent.torrent", seeders=10, leechers=5, size_gb=1.0, source="test", info_hash="")
    assert r.is_magnet == False

if __name__ == "__main__":
    test_search_result_creation()
    test_search_result_is_magnet()
    print("All provider base tests passed!")
