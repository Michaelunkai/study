# qbittorrent/client.py
import requests
import json
import time

class QBittorrentClient:
    def __init__(self, config: dict):
        qb_config = config.get('qbittorrent', {})
        self.url = qb_config.get('url', 'http://127.0.0.1:18080')
        self.username = qb_config.get('username', 'admin')
        self.password = qb_config.get('password', 'adminadmin')
        self.save_path = qb_config.get('save_path', 'F:/Downloads')
        self.session = requests.Session()

    def login(self) -> bool:
        try:
            r = self.session.post(f"{self.url}/api/v2/auth/login",
                                data={'username': self.username, 'password': self.password},
                                timeout=5)
            return r.status_code == 200 and "Ok" in r.text
        except:
            return False

    def configure(self):
        try:
            prefs = {
                'dl_limit': 0, 'up_limit': 0,
                'max_active_downloads': -1, 'max_active_torrents': -1,
                'dont_start_auto_download': 0, 'save_path': self.save_path
            }
            self.session.post(f"{self.url}/api/v2/app/setPreferences",
                            data={'json': json.dumps(prefs)}, timeout=5)
        except:
            pass

    def add_torrent(self, magnet: str, name: str = "") -> bool:
        for attempt in range(3):
            try:
                data = {"urls": magnet, "paused": "false", "skip_checking": "false"}
                if name:
                    data["rename"] = name[:100]
                r = self.session.post(f"{self.url}/api/v2/torrents/add",
                                    data=data, timeout=15)
                if r.status_code == 200 and "Ok" in r.text:
                    return True
                self.login()
                time.sleep(1)
            except:
                time.sleep(1)
        return False

    def get_torrents(self) -> list:
        try:
            r = self.session.get(f"{self.url}/api/v2/torrents/info", timeout=10)
            if r.status_code == 200:
                return r.json()
        except:
            pass
        return []
