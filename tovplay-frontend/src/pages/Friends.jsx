import { Heart, Users, UserPlus, MessageCircle } from "lucide-react";
import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { samplePlayers } from "../components/data/samplePlayers";
import { createPageUrl } from "@/utils";

export default function Friends() {
  const [currentUser, setCurrentUser] = useState(null);
  const [friends, setFriends] = useState([]);
  const [friendRequests, setFriendRequests] = useState([]);

  useEffect(() => {
    // Get current user (in real app this would be User.me())
    const user = samplePlayers.find(p => p.username === "GamerAlex");
    setCurrentUser(user);

    if (user) {
      // Get friends data
      const userFriends = samplePlayers.filter(p =>
        user.friends.includes(p.username)
      );
      setFriends(userFriends);

      // Mock friend requests (in real app this would be from FriendRequest entity)
      setFriendRequests([
        {
          id: 1,
          sender_username: "BuilderBee",
          status: "pending",
          created_date: new Date().toISOString()
        }
      ]);
    }
  }, []);

  const handleAcceptRequest = requestId => {
    // In real app: FriendRequest.update(requestId, { status: 'accepted' })
    setFriendRequests(prev => prev.filter(r => r.id !== requestId));
    // Also add to friends list in real implementation
  };

  const handleDeclineRequest = requestId => {
    // In real app: FriendRequest.update(requestId, { status: 'declined' })
    setFriendRequests(prev => prev.filter(r => r.id !== requestId));
  };

  const isOnline = lastSeen => {
    if (!lastSeen) {
      return false;
    }
    return new Date(lastSeen) > new Date(Date.now() - 6 * 60 * 1000);
  };

  if (!currentUser) {
    return <div className="flex justify-center items-center h-screen"><div className="text-xl text-gray-600">Loading...</div></div>;
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-800 mb-2">Friends</h1>
        <p className="text-gray-600">Manage your gaming connections and friend requests.</p>
      </div>

      {/* Friend Requests */}
      {friendRequests.length > 0 && (
        <div className="calm-card mb-8">
          <div className="flex items-center space-x-3 mb-6">
            <UserPlus className="w-6 h-6 text-teal-600" />
            <h2 className="text-xl font-semibold text-gray-800">Friend Requests</h2>
          </div>
          <div className="space-y-4">
            {friendRequests.map(request => {
              const sender = samplePlayers.find(p => p.username === request.sender_username);
              return (
                <div key={request.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-gradient-to-br from-teal-50 to-teal-100 rounded-full flex items-center justify-center">
                      <Users className="w-6 h-6 text-teal-600" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-800">{request.sender_username}</h3>
                      <p className="text-sm text-gray-600">Wants to be your friend</p>
                    </div>
                  </div>
                  <div className="flex space-x-2">
                    <button
                      onClick={() => handleDeclineRequest(request.id)}
                      className="px-4 py-2 bg-white border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                    >
                      Decline
                    </button>
                    <button
                      onClick={() => handleAcceptRequest(request.id)}
                      className="px-4 py-2 bg-teal-500 text-white rounded-lg hover:bg-teal-600 transition-colors"
                    >
                      Accept
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Friends List */}
      <div className="calm-card">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <Heart className="w-6 h-6 text-teal-600" />
            <h2 className="text-xl font-semibold text-gray-800">Your Friends ({friends.length})</h2>
          </div>
          <Link to={createPageUrl("FindPlayers")}>
            <button className="flex items-center space-x-2 px-4 py-2 bg-teal-500 text-white rounded-lg hover:bg-teal-600 transition-colors">
              <UserPlus className="w-4 h-4" />
              <span>Find More Friends</span>
            </button>
          </Link>
        </div>

        {friends.length > 0 ? (
          <div className="grid md:grid-cols-2 gap-4">
            {friends.map(friend => (
              <div key={friend.username} className="p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-teal-50 to-teal-100 rounded-full flex items-center justify-center relative">
                      <Users className="w-5 h-5 text-teal-600" />
                      {isOnline(friend.last_seen) && (
                        <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 rounded-full border-2 border-white"></div>
                      )}
                    </div>
                    <div>
                      <Link to={createPageUrl(`UserProfile?username=${friend.username}`)}>
                        <h3 className="font-semibold text-gray-800 hover:text-teal-600 transition-colors">
                          {friend.username}
                        </h3>
                      </Link>
                      <p className="text-xs text-gray-500">
                        {isOnline(friend.last_seen) ? "Online now" : "Offline"}
                      </p>
                    </div>
                  </div>
                  <button className="p-2 text-gray-400 hover:text-teal-600 transition-colors">
                    <MessageCircle className="w-4 h-4" />
                  </button>
                </div>
                <div className="flex flex-wrap gap-1">
                  {friend.games.slice(0, 3).map((game, index) => (
                    <span key={index} className="px-2 py-1 bg-white text-xs text-gray-600 rounded">
                      {game}
                    </span>
                  ))}
                  {friend.games.length > 3 && (
                    <span className="px-2 py-1 bg-white text-xs text-gray-500 rounded">
                      +{friend.games.length - 3}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Heart className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-800 mb-2">No friends yet</h3>
            <p className="text-gray-500 mb-4">Start connecting with other players to build your friend list.</p>
            <Link to={createPageUrl("FindPlayers")}>
              <button className="px-6 py-2 bg-teal-500 text-white rounded-lg hover:bg-teal-600 transition-colors">
                Find Players
              </button>
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
