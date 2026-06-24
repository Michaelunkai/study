import re

MOVIE_VIDEO_MARKERS = [
    '1080p', '720p', '2160p', '4k', 'web-dl', 'webrip', 'bluray', 'bdrip',
    'dvdrip', 'h264', 'h265', 'hevc', 'x264', 'x265', 'xvid', 'brrip',
    'hdtv', 'remux', 'hdrip', 'cam', 'hdcam', 'ts', 'tc', 'screener',
    'dts', 'dolby', 'atmos', '5.1', '7.1', 'subbed', 'dubbed',
    'extended', 'theatrical', 'directors cut', 'unrated', 'imax',
    'web', 'webhd', 'hdrip', 'bdrip', 'brrip', 'dvd', 'hddvd',
    'proper', 'rerip', 'rarbg', 'yify', 'yts',
]

MOVIE_YEAR_PATTERN = re.compile(r'[\.\s\[\(](19|20)\d{2}[\.\s\]\)]')

TV_MARKERS = [
    's01e', 's02e', 's03e', 's04e', 's05e', 's06e', 's07e', 's08e',
    's09e', 's10e', 's11e', 's12e', 'season', 'series', 'episode',
    'ep01', 'ep02', 'complete series', 'all seasons'
]

JUNK_MARKERS = [
    'wallpaper', 'strategy guide', 'artbook', 'subtitle',
    'ebook', 'manual', 'trainer', 'cheat', 'save game',
    ' cracked', 'crack only', 'keygen', 'keymaker', 'patch only'
]

GAME_REPACK_GROUPS = [
    'fitgirl', 'dodi', 'tenoke', 'reloaded', 'kaos', 'empress',
    'elamigos', 'razor1911', 'codex', 'cpy', 'skidrow', 'plaza',
    'corepack', 'rune', 'mercs', 'iso', 'gog', 'steamrip',
    'rgmechanics', 'bgm', 'chronos', 'dodigames', 'fckdrm',
    'goggame', 'pooeen', 'xatab', 'russianduck', 'mechanics',
]

GAME_EDITION_MARKERS = [
    'goty', 'deluxe', 'ultimate', 'dlc', 'complete edition',
    'premium edition', 'gold edition', 'definitive', 'enhanced edition',
    'game of the year', 'digital deluxe', 'legacy', 'collection',
    'anthology', 'bundle', 'pack',
]

GAME_PLATFORM_MARKERS = [
    'pc game', 'pc dvd', 'pc iso', 'windows', 'steam', 'epic games',
    'gog', 'origin', 'uplay', 'rockstar', 'battle.net', 'battlenet',
    'game', 'steamrip',
]

GAME_EXTENSIONS = ['.iso', '.bin', '.exe', '.msi', '.nsp', '.xci', '.cia',
                   '.pkg', '.rap', '.edat', '.iso.xdelta']

GAME_SIZE_MIN_GB = 1.0
GAME_SIZE_MAX_GB = 150.0


class GameDetector:
    def _has_game_group(self, name: str) -> bool:
        n = name.lower()
        return any(g in n for g in GAME_REPACK_GROUPS)

    def _has_movie_markers(self, name: str) -> bool:
        n = name.lower()
        movie_count = sum(1 for s in MOVIE_VIDEO_MARKERS if s in n)
        return movie_count >= 1

    def _has_year(self, name: str) -> bool:
        return bool(MOVIE_YEAR_PATTERN.search(name.lower()))

    def is_game(self, name: str) -> bool:
        n = name.lower().strip()

        for marker in TV_MARKERS:
            if marker in n:
                return False

        for marker in JUNK_MARKERS:
            if marker in n:
                return False

        for ext in GAME_EXTENSIONS:
            if n.rstrip().endswith(ext):
                return True

        if self._has_game_group(n):
            return True

        for marker in GAME_EDITION_MARKERS:
            if marker in n:
                return True

        for marker in GAME_PLATFORM_MARKERS:
            if marker in n:
                return True

        if self._has_movie_markers(n):
            return False

        if self._has_year(n):
            return False

        size_match = re.search(r'(\d+\.?\d*)\s*(gb|mb|tb)', n)
        if size_match:
            size_val = float(size_match.group(1))
            size_unit = size_match.group(2)
            if size_unit == 'gb' and GAME_SIZE_MIN_GB <= size_val <= GAME_SIZE_MAX_GB:
                return True
            if size_unit == 'tb' and size_val <= 1:
                return True

        return False

    def is_definitely_not_game(self, name: str) -> bool:
        n = name.lower().strip()

        if self._has_game_group(n):
            return False

        for marker in MOVIE_VIDEO_MARKERS:
            if marker in n:
                return True

        if self._has_year(n):
            return True

        for marker in TV_MARKERS:
            if marker in n:
                return True

        size_match = re.search(r'(\d+\.?\d*)\s*(gb|mb|tb)', n)
        if size_match:
            size_val = float(size_match.group(1))
            size_unit = size_match.group(2)
            if size_unit == 'mb' and size_val < 500:
                return True
            if size_unit == 'gb' and size_val < 1.0:
                return True

        return False
