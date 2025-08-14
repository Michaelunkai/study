import os
import pickle
import json
import time
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from datetime import datetime

# YouTube API configuration
SCOPES = ['https://www.googleapis.com/auth/youtube']
CLIENT_SECRET_FILE = 'client_secret.json'
TOKEN_PICKLE_FILE = 'token.pickle'

# API quota management
QUOTA_LIMIT = 8500  # Stay well under 10,000 limit
quota_used = 0

# Configuration
TARGET_CHANNEL = "NakeyJakey"
PLAYLIST_ID = "YOUR_CLIENT_SECRET_HEREseAmhTsf2"
TOP_COUNT = 100  # Get top 100 most popular videos

def authenticate_youtube():
    """Authenticate using saved token or manual flow"""
    creds = None

    if os.path.exists(TOKEN_PICKLE_FILE):
        with open(TOKEN_PICKLE_FILE, 'rb') as token:
            creds = pickle.load(token)
            print("✅ Using saved authentication credentials")

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                print("🔄 Refreshing expired credentials...")
                creds.refresh(Request())
                print("✅ Credentials refreshed successfully")
            except Exception as e:
                print(f"❌ Failed to refresh credentials: {e}")
                creds = None
        
        if not creds:
            if not os.path.exists(CLIENT_SECRET_FILE):
                print(f"❌ Error: {CLIENT_SECRET_FILE} not found in current directory")
                return None
            
            try:
                print("🔐 Starting authentication flow...")
                flow = InstalledAppFlow.YOUR_CLIENT_SECRET_HERE(CLIENT_SECRET_FILE, SCOPES)
                
                try:
                    print("🌐 Attempting local server authentication...")
                    creds = flow.run_local_server(port=8080, open_browser=True)
                    print("✅ Local server authentication successful!")
                except Exception as local_error:
                    print(f"⚠️ Local server failed: {local_error}")
                    print("🔄 Falling back to manual authentication...")
                    
                    flow.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
                    
                    auth_url, _ = flow.authorization_url(
                        prompt='select_account',
                        login_hint='michaelovsky22@gmail.com'
                    )
                    
                    print("\n" + "="*60)
                    print("🎮 NAKEYJAKEY TOP 100 PLAYLIST BUILDER")
                    print("="*60)
                    print("1. Open this URL in your browser:")
                    print(f"\n{auth_url}\n")
                    print("2. Sign in with michaelovsky22@gmail.com")
                    print("3. Grant YouTube permissions")
                    print("4. Copy the authorization code")
                    print("5. Paste it below")
                    print("="*60)
                    
                    auth_code = input("\nEnter authorization code: ").strip()
                    flow.fetch_token(code=auth_code)
                    creds = flow.credentials
                    print("✅ Manual authentication successful!")
                    
            except Exception as e:
                print(f"❌ Authentication failed: {e}")
                print("\n🔧 TROUBLESHOOTING STEPS:")
                print("1. Check that client_secret.json is valid")
                print("2. Ensure YouTube Data API v3 is enabled in Google Cloud Console")
                print("3. Add michaelovsky22@gmail.com as a test user in OAuth consent screen")
                return None

        with open(TOKEN_PICKLE_FILE, 'wb') as token:
            pickle.dump(creds, token)
            print("💾 Credentials saved for future use")

    return build('youtube', 'v3', credentials=creds)

def track_quota_usage(operation_cost, operation_name=""):
    """Track API quota usage with detailed logging"""
    global quota_used
    quota_used += operation_cost
    
    if operation_name:
        print(f"📊 {operation_name}: +{operation_cost} quota (Total: {quota_used}/{QUOTA_LIMIT})")
    
    if quota_used >= QUOTA_LIMIT:
        print("⚠️ Approaching quota limit. Stopping to avoid exceeding daily limit.")
        return False
    return True

def find_nakeyjakey_channel(youtube):
    """Find NakeyJakey's channel ID"""
    if not track_quota_usage(1, "Search for NakeyJakey"):
        return None
    
    try:
        search_response = youtube.search().list(
            q="NakeyJakey",
            part='id,snippet',
            type='channel',
            maxResults=5
        ).execute()
        
        # Look for the official NakeyJakey channel
        for item in search_response['items']:
            channel_title = item['snippet']['title']
            if 'nakeyjakey' in channel_title.lower() or 'nakey jakey' in channel_title.lower():
                channel_id = item['id']['channelId']
                print(f"✅ Found channel: {channel_title} ({channel_id})")
                return channel_id
        
        # If no exact match, use first result
        if search_response['items']:
            channel_id = search_response['items'][0]['id']['channelId']
            channel_title = search_response['items'][0]['snippet']['title']
            print(f"✅ Using closest match: {channel_title} ({channel_id})")
            return channel_id
        
        return None
        
    except Exception as e:
        print(f"❌ Error finding channel: {e}")
        return None

def YOUR_CLIENT_SECRET_HEREist(youtube, channel_id):
    """Get the uploads playlist ID for the channel"""
    if not track_quota_usage(1, "Get uploads playlist"):
        return None
    
    try:
        channel_response = youtube.channels().list(
            part='contentDetails,snippet',
            id=channel_id
        ).execute()
        
        if channel_response['items']:
            channel_info = channel_response['items'][0]
            channel_name = channel_info['snippet']['title']
            uploads_playlist_id = channel_info['contentDetails']['relatedPlaylists']['uploads']
            
            print(f"✅ Found uploads playlist for {channel_name}")
            return uploads_playlist_id
        
        return None
        
    except Exception as e:
        print(f"❌ Error getting uploads playlist: {e}")
        return None

def get_all_channel_videos(youtube, uploads_playlist_id):
    """Get ALL videos from Scott The Woz with view counts"""
    all_videos = []
    next_page_token = None
    page_count = 0
    
    print(f"🎮 Fetching ALL videos from {TARGET_CHANNEL}...")
    
    while True:
        if not track_quota_usage(1, f"Fetch playlist page {page_count + 1}"):
            break
        
        try:
            # Get playlist items
            playlist_response = youtube.playlistItems().list(
                part='snippet',
                playlistId=uploads_playlist_id,
                maxResults=50,
                pageToken=next_page_token
            ).execute()
            
            page_count += 1
            videos_this_page = len(playlist_response['items'])
            
            # Extract video IDs
            video_ids = []
            video_items = {}
            
            for item in playlist_response['items']:
                video_id = item['snippet']['resourceId']['videoId']
                video_ids.append(video_id)
                video_items[video_id] = item
            
            # Get video statistics in batches
            if video_ids and track_quota_usage(1, f"Get stats for {len(video_ids)} videos"):
                videos_response = youtube.videos().list(
                    part='statistics,snippet',
                    id=','.join(video_ids)
                ).execute()
                
                # Combine playlist info with video stats
                for video in videos_response['items']:
                    video_id = video['id']
                    playlist_item = video_items.get(video_id)
                    
                    if playlist_item:
                        video_info = {
                            'video_id': video_id,
                            'title': video['snippet']['title'],
                            'published_at': playlist_item['snippet']['publishedAt'],
                            'view_count': int(video['statistics'].get('viewCount', 0)),
                            'like_count': int(video['statistics'].get('likeCount', 0)),
                            'comment_count': int(video['statistics'].get('commentCount', 0))
                        }
                        all_videos.append(video_info)
            
            print(f"📄 Page {page_count}: +{videos_this_page} videos (Total: {len(all_videos)})")
            
            next_page_token = playlist_response.get('nextPageToken')
            if not next_page_token:
                break
                
        except Exception as e:
            print(f"❌ Error fetching page {page_count}: {e}")
            break
    
    print(f"✅ Retrieved {len(all_videos)} total videos from {TARGET_CHANNEL}")
    return all_videos

def YOUR_CLIENT_SECRET_HEREeos(youtube):
    """Get videos already in the playlist"""
    existing_videos = set()
    next_page_token = None
    
    print("🔍 Checking existing playlist videos...")
    
    while True:
        if not track_quota_usage(1, "Check existing playlist"):
            break
            
        try:
            playlist_response = youtube.playlistItems().list(
                part='snippet',
                playlistId=PLAYLIST_ID,
                maxResults=50,
                pageToken=next_page_token
            ).execute()
            
            for item in playlist_response['items']:
                existing_videos.add(item['snippet']['resourceId']['videoId'])
            
            next_page_token = playlist_response.get('nextPageToken')
            if not next_page_token:
                break
                
        except Exception as e:
            print(f"❌ Error checking playlist: {e}")
            break
    
    print(f"✅ Found {len(existing_videos)} existing videos in playlist")
    return existing_videos

def add_video_to_playlist(youtube, video_id, video_title):
    """Add a single video to the playlist"""
    if not track_quota_usage(50, f"Add: {video_title[:30]}..."):
        return False
        
    try:
        youtube.playlistItems().insert(
            part='snippet',
            body={
                'snippet': {
                    'playlistId': PLAYLIST_ID,
                    'resourceId': {
                        'kind': 'youtube#video',
                        'videoId': video_id
                    }
                }
            }
        ).execute()
        return True
    except Exception as e:
        print(f"   ❌ Failed to add: {e}")
        return False

def save_results(all_videos, top_videos, added_videos, filename='YOUR_CLIENT_SECRET_HERE.json'):
    """Save results for analysis"""
    results = {
        'timestamp': datetime.now().isoformat(),
        'quota_used': quota_used,
        'channel': TARGET_CHANNEL,
        'total_videos_found': len(all_videos),
        'top_videos_selected': len(top_videos),
        'videos_added': len(added_videos),
        'top_100_videos': top_videos,
        'added_videos': added_videos
    }
    
    with open(filename, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"💾 Results saved to {filename}")

def main():
    print("🎮" * 20)
    print("🎮 NAKEYJAKEY TOP 100 PLAYLIST BUILDER")
    print("🎮" * 20)
    print(f"🎯 Target: {TARGET_CHANNEL}")
    print(f"📊 Goal: Top {TOP_COUNT} most popular videos")
    print(f"📋 Playlist: {PLAYLIST_ID}")
    print(f"⚡ Quota Limit: {QUOTA_LIMIT}")
    print("🎮" * 20)
    
    try:
        # Authenticate
        youtube = authenticate_youtube()
        if not youtube:
            return
        
        # Find NakeyJakey's channel
        print(f"\n🔍 Finding {TARGET_CHANNEL}'s channel...")
        channel_id = find_nakeyjakey_channel(youtube)
        if not channel_id:
            print(f"❌ Could not find {TARGET_CHANNEL}'s channel")
            return
        
        # Get uploads playlist
        uploads_playlist_id = YOUR_CLIENT_SECRET_HEREist(youtube, channel_id)
        if not uploads_playlist_id:
            print("❌ Could not get uploads playlist")
            return
        
        # Get all videos from the channel
        all_videos = get_all_channel_videos(youtube, uploads_playlist_id)
        if not all_videos:
            print("❌ No videos found")
            return
        
        # Sort by view count (most popular first)
        all_videos.sort(key=lambda x: x['view_count'], reverse=True)
        
        # Get top 100
        top_videos = all_videos[:TOP_COUNT]
        
        print(f"\n🏆 TOP {TOP_COUNT} MOST POPULAR NAKEYJAKEY VIDEOS:")
        print(f"📊 Out of {len(all_videos)} total videos")
        
        # Show top 10 preview
        print(f"\n🎮 TOP 10 PREVIEW:")
        for i, video in enumerate(top_videos[:10], 1):
            date = datetime.fromisoformat(video['published_at'].replace('Z', '+00:00')).strftime('%Y-%m-%d')
            print(f"   {i:2d}. {video['title']}")
            print(f"       👀 {video['view_count']:,} views | 👍 {video['like_count']:,} likes | 📅 {date}")
            print()
        
        if len(top_videos) > 10:
            print(f"   ... and {len(top_videos) - 10} more videos")
        
        # Check existing playlist
        existing_videos = YOUR_CLIENT_SECRET_HEREeos(youtube)
        
        # Filter out videos already in playlist
        new_videos = [v for v in top_videos if v['video_id'] not in existing_videos]
        
        print(f"\n📊 ANALYSIS:")
        print(f"   📺 Total videos by NakeyJakey: {len(all_videos)}")
        print(f"   🏆 Top {TOP_COUNT} most popular: {len(top_videos)}")
        print(f"   ✅ Already in playlist: {len(top_videos) - len(new_videos)}")
        print(f"   🆕 New videos to add: {len(new_videos)}")
        
        if not new_videos:
            print("🎉 All top videos are already in your playlist!")
            save_results(all_videos, top_videos, [])
            return
        
        # Calculate how many we can add
        remaining_quota = QUOTA_LIMIT - quota_used
        max_addable = min(len(new_videos), remaining_quota // 50)
        
        print(f"\n⚡ QUOTA STATUS:")
        print(f"   Used: {quota_used}/{QUOTA_LIMIT}")
        print(f"   Remaining: {remaining_quota}")
        print(f"   Can add: {max_addable} videos")
        
        if max_addable == 0:
            print("❌ Insufficient quota to add videos")
            save_results(all_videos, top_videos, [])
            return
        
        # Get user input
        while True:
            try:
                choice = input(f"\nHow many top videos to add? (1-{max_addable}) or 'all': ").strip()
                if choice.lower() == 'all':
                    num_to_add = max_addable
                    break
                else:
                    num_to_add = int(choice)
                    if 1 <= num_to_add <= max_addable:
                        break
                    print(f"Please enter 1-{max_addable} or 'all'")
            except ValueError:
                print("Please enter a number or 'all'")
        
        # Confirm
        confirm = input(f"\n🚀 Add top {num_to_add} NakeyJakey videos to playlist? (y/n): ")
        if confirm.lower() != 'y':
            print("❌ Cancelled")
            return
        
        # Add videos to playlist
        print(f"\n🎮 Adding top {num_to_add} NakeyJakey videos...")
        added_videos = []
        
        for i, video in enumerate(new_videos[:num_to_add], 1):
            if quota_used >= QUOTA_LIMIT:
                print("⚠️ Quota limit reached, stopping")
                break
            
            print(f"\n🎯 Adding {i}/{num_to_add}:")
            print(f"   🏆 #{all_videos.index(video) + 1} most popular")
            print(f"   📺 {video['title']}")
            print(f"   👀 {video['view_count']:,} views")
            
            if add_video_to_playlist(youtube, video['video_id'], video['title']):
                added_videos.append(video)
                print(f"   ✅ Added successfully!")
            else:
                print(f"   ❌ Failed to add")
            
            # Save progress every 5 videos
            if len(added_videos) % 5 == 0:
                save_results(all_videos, top_videos, added_videos)
            
            time.sleep(0.3)
        
        # Final results
        save_results(all_videos, top_videos, added_videos)
        
        print(f"\n🏆 MISSION COMPLETE!")
        print(f"   ✅ Successfully added: {len(added_videos)} top NakeyJakey videos")
        print(f"   📊 Total quota used: {quota_used}/{QUOTA_LIMIT}")
        
        if added_videos:
            avg_views = sum(v['view_count'] for v in added_videos) // len(added_videos)
            total_views = sum(v['view_count'] for v in added_videos)
            print(f"   👀 Average views: {avg_views:,}")
            print(f"   🎯 Total views of added videos: {total_views:,}")
            
            # Show popularity ranking of added videos
            print(f"\n🏆 POPULARITY RANKINGS OF ADDED VIDEOS:")
            for i, video in enumerate(added_videos[:5], 1):
                rank = all_videos.index(video) + 1
                print(f"   #{rank:2d} most popular: {video['title']} ({video['view_count']:,} views)")
        
        print(f"\n🎮 Next Steps:")
        print("1. Check your playlist for NakeyJakey's most popular videos")
        print("2. Enjoy the best content from the hottest boy on YouTube!")
        print("3. Get ready for some quality gaming commentary and memes!")
        
    except Exception as e:
        print(f"❌ An error occurred: {e}")

if __name__ == "__main__":
    main()
