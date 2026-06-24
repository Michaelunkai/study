import sys
import os
import yaml
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from providers.base import SearchProvider, SearchResult
from providers.jackett import JackettProvider
from providers.prowlarr import ProwlarrProvider
from providers.thepiratebay import ThePirateBayProvider
from providers.leetx import LeetxProvider
from providers.torrentgalaxy import TorrentGalaxyProvider
from providers.nyaa import NyaaProvider
from matching.normalizer import QueryNormalizer
from matching.scorer import ConfidenceScorer
from matching.game_detector import GameDetector
from ranking.ranker import Ranker
from qbittorrent.client import QBittorrentClient

def load_config():
    config_path = Path(__file__).parent / "config.yaml"
    if config_path.exists():
        with open(config_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    return {}

def get_providers(config: dict) -> list:
    providers = []
    provider_classes = [
        JackettProvider,
        ProwlarrProvider,
        ThePirateBayProvider,
        LeetxProvider,
        TorrentGalaxyProvider,
        NyaaProvider,
    ]
    for cls in provider_classes:
        try:
            p = cls(config)
            providers.append(p)
        except Exception as e:
            print(f"  Failed to init {cls.name}: {e}")
    return providers

def search_all_sources(providers: list, query: str, config: dict) -> list:
    max_timeout = config.get('search', {}).get('timeout_per_source', 15)
    all_results = []

    available = []
    for p in providers:
        try:
            if p.is_available():
                available.append(p)
                print(f"  [{p.name}] Online")
            else:
                print(f"  [{p.name}] Offline")
        except:
            print(f"  [{p.name}] Offline")

    if not available:
        print("  WARNING: No search providers available!")
        return all_results

    def do_search(provider):
        try:
            return provider.search(query)
        except Exception as e:
            print(f"  [{provider.name}] Error: {e}")
            return []

    with ThreadPoolExecutor(max_workers=len(available)) as executor:
        futures = {executor.submit(do_search, p): p for p in available}
        for future in as_completed(futures, timeout=max_timeout + 5):
            provider = futures[future]
            try:
                results = future.result(timeout=max_timeout)
                all_results.extend(results)
                print(f"  [{provider.name}] Found {len(results)} results")
            except Exception as e:
                print(f"  [{provider.name}] Timeout/Error: {e}")

    return all_results

def format_size(gb):
    if gb >= 1:
        return f"{gb:.2f} GB"
    return f"{gb*1024:.2f} MB"

def main():
    if len(sys.argv) < 2:
        print("Usage: python cli_downloader.py 'game 1' 'game 2' ...")
        sys.exit(1)

    search_terms = sys.argv[1:]
    print(f"=== Game Torrent Downloader v2.0 ===")
    print(f"Searching for {len(search_terms)} game(s)...\n")

    config = load_config()
    aliases = config.get('aliases', {})
    confidence_threshold = config.get('search', {}).get('confidence_threshold', 50)

    normalizer = QueryNormalizer(aliases)
    scorer = ConfidenceScorer(normalizer)
    ranker = Ranker(normalizer, scorer)
    detector = GameDetector()
    qb = QBittorrentClient(config)

    if not qb.login():
        print("ERROR: Could not connect to qBittorrent WebUI")
        sys.exit(1)
    qb.configure()

    providers = get_providers(config)
    print(f"\nAvailable providers: {len(providers)}")

    success = 0
    for term in search_terms:
        print(f"\n{'='*50}")
        print(f"Searching for: {term}")

        expansions = normalizer.expand(term)
        print(f"  Query variants: {expansions}")

        all_results = []
        for expansion in expansions:
            results = search_all_sources(providers, expansion, config)
            all_results.extend(results)

        if not all_results:
            print(f"  No results found for '{term}'")
            continue

        print(f"\n  Total raw results: {len(all_results)}")

        ranked = ranker.rank(term, all_results, confidence_threshold)
        print(f"  After ranking: {len(ranked)} matches above threshold {confidence_threshold}")

        if not ranked:
            print(f"  No game matches found for '{term}'")
            print("  Tip: Try a more specific name or check if the game is available as a torrent")
            continue

        best = ranked[0]
        print(f"\n  BEST MATCH:")
        print(f"    Title:    {best.title}")
        print(f"    Seeders:  {best.seeders}")
        print(f"    Leechers: {best.leechers}")
        print(f"    Size:     {format_size(best.size_gb)}")
        print(f"    Source:   {best.source}")
        print(f"    Confidence: {scorer.score(term, best.title)}/100")

        if qb.add_torrent(best.url, best.title):
            print(f"  >> ADDED TO QBITTORRENT!")
            success += 1
        else:
            print(f"  >> FAILED to add to qBittorrent")

    print(f"\n{'='*50}")
    print(f"=== Done: {success}/{len(search_terms)} games added ===")
    sys.exit(0 if success == len(search_terms) else 1)

if __name__ == "__main__":
    main()
