import re

MOVIE_MARKERS = [
    '1080p', '720p', '2160p', '4k', 'web-dl', 'webrip', 'bluray', 'bdrip',
    'dvdrip', 'h264', 'h265', 'hevc', 'x264', 'x265', 'xvid', 'brrip',
    'hdtv', 'remux', 'hdrip', 'cam', 'hdcam', 'ts', 'tc', 'screener',
    'dts', 'dolby', 'atmos', 'aac', 'mp3', 'ac3', '5.1', '7.1',
    'hdrip', 'subbed', 'dubbed', 'multi', 'extended', 'theatrical',
    'directors cut', 'unrated', 'imax'
]

MUSIC_MARKERS = [
    'mp3', 'flac', '.wav', 'aac', 'album', 'disc', 'vinyl', 'cd',
    'tracks', 'tracklist', '320kbps', 'vbr', 'opus', 'ogg', 'm4a',
    'soundtrack', 'ost', 'ep', 'single', 'lp', 'remix', 'mixtape'
]

TV_MARKERS = [
    's01e', 's02e', 's03e', 's04e', 's05e', 's06e', 's07e', 's08e',
    's09e', 's10e', 's11e', 's12e', 'season', 'series', 'episode',
    'ep01', 'ep02', 'complete series', 'all seasons'
]

JUNK_MARKERS = [
    'wallpaper', 'soundtrack', 'strategy guide', 'artbook', 'subtitle',
    'ebook', 'manual', 'trainer', 'cheat', 'save game', 'mod',
    ' cracked', 'crack only', 'keygen', 'keymaker', 'patch only'
]

GAME_POSITIVE = [
    'fitgirl', 'dodi', 'tenoke', 'reloaded', 'repack', 'kaos', 'empress',
    'elamigos', 'razor1911', 'codex', 'cpy', 'skidrow', 'plaza', 'corepack',
    'rune', 'gog', 'steam', 'epic', 'goty', 'deluxe', 'ultimate', 'dlc', 'complete',
    'steamrip', 'pcdvd', 'pc iso', 'full game', 'pc game', 'game',
    'repack', 'repacked', 'pre-installed', 'portable',
    '.iso', '.bin', '.exe', '.msi', '.bin.xdelta', '.cia', '.nsp', '.xci'
]

GAME_EXTENSIONS = ['.iso', '.bin', '.exe', '.msi', '.nsp', '.xci', '.cia',
                   '.pkg', '.rap', '.edat', '.iso.xdelta']

class GameDetector:
    def is_game(self, name: str) -> bool:
        n = name.lower()

        for marker in TV_MARKERS:
            if marker in n:
                return False

        for marker in JUNK_MARKERS:
            if marker in n:
                return False

        for ext in GAME_EXTENSIONS:
            if n.rstrip().endswith(ext):
                return True

        for marker in GAME_POSITIVE:
            if marker in n:
                return True

        movie_score = sum(1 for s in MOVIE_MARKERS if s in n)
        if movie_score >= 4:
            return False

        music_score = sum(1 for s in MUSIC_MARKERS if s in n)
        if music_score >= 2:
            return False

        size_match = re.search(r'(\d+\.?\d*)\s*(gb|mb|tb)', n)
        if size_match:
            size_val = float(size_match.group(1))
            size_unit = size_match.group(2)
            if size_unit == 'gb' and 1 < size_val < 200:
                return True
            if size_unit == 'mb' and 50 < size_val < 5000:
                return True

        if re.search(r'(repack|repacked)', n):
            return True

        return False
