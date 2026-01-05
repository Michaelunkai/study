import { User, MessageCircle, UserPlus, Check, Edit, Mic, MessageSquare, VolumeX, Shield, Users, AlertTriangle } from "lucide-react";
import { useState } from "react";
import RequestModal from "../RequestModal";

export default function ProfileHeader({ player, isMyProfile, onEditClick }) {
  const [showRequestModal, setShowRequestModal] = useState(false);
  const [friendRequestSent, setFriendRequestSent] = useState(false);

  const handleAddFriend = () => {
    setFriendRequestSent(true);
  };

  const getCommunicationIcon = commType => {
    switch (commType) {
      case "voice_messages":
        return <Mic className="w-4 h-4" />;
      case "prefer_no_talking":
        return <VolumeX className="w-4 h-4" />;
      default:
        return <MessageSquare className="w-4 h-4" />;
    }
  };

  const getCommunicationLabel = commType => {
    switch (commType) {
      case "voice_messages":
        return "Voice Messages";
      case "prefer_no_talking":
        return "Prefer No Talking";
      default:
        return "Written Messages";
    }
  };

  const getOpennessIcon = openness => {
    switch (openness) {
      case "careful":
        return <AlertTriangle className="w-4 h-4" />;
      case "only_previous":
        return <Shield className="w-4 h-4" />;
      default:
        return <Users className="w-4 h-4" />;
    }
  };

  const getOpennessLabel = openness => {
    switch (openness) {
      case "careful":
        return "Careful with new people";
      case "only_previous":
        return "Only previous contacts";
      default:
        return "Open to new people";
    }
  };

  return (
    <>
      <div className="calm-card bg-gradient-to-r from-white to-gray-50 border-gray-200">
        <div className="flex flex-col lg:flex-row items-center lg:items-start lg:space-x-8">
          {/* Profile Image Section */}
          <div className="flex-shrink-0 mb-6 lg:mb-0">
            <div className="relative">
              <div className="w-32 h-32 bg-gradient-to-br from-teal-100 to-teal-200 rounded-2xl flex items-center justify-center overflow-hidden shadow-lg">
                {player.profilePhoto ? (
                  <img
                    src={player.profilePhoto}
                    alt={`${player.username}'s profile`}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <User className="w-16 h-16 text-teal-600" />
                )}
              </div>
              {/* Online status indicator */}
              <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-green-500 rounded-full border-4 border-white shadow-lg flex items-center justify-center">
                <div className="w-3 h-3 bg-white rounded-full"></div>
              </div>
            </div>
          </div>

          {/* Profile Info Section */}
          <div className="flex-grow text-center lg:text-left lg:py-4">
            <div className="mb-4">
              <h1 className="text-4xl font-bold text-gray-800 mb-2">{player.username}</h1>
              {player.description ? (
                <p className="text-gray-600 leading-relaxed text-lg">{player.description}</p>
              ) : (
                <p className="text-gray-600 text-lg">Loves playing {player.games[0]} and {player.games[1]}</p>
              )}
            </div>

            {/* Stats Row */}
            <div className="flex justify-center lg:justify-start space-x-8 mb-6">
              <div className="text-center">
                <p className="text-2xl font-bold text-teal-600">{player.friends.length}</p>
                <p className="text-sm text-gray-500">Friends</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-teal-600">{player.games.length}</p>
                <p className="text-sm text-gray-500">Games</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-teal-600">24</p>
                <p className="text-sm text-gray-500">Sessions</p>
              </div>
            </div>
          </div>

          {/* Action Buttons Section */}
          <div className="flex-shrink-0 lg:py-4">
            {isMyProfile ? (
              <button
                onClick={onEditClick}
                className="calm-button flex items-center justify-center space-x-2 px-6 py-3"
              >
                <Edit className="w-5 h-5" />
                <span>Edit Profile</span>
              </button>
            ) : (
              <div className="flex flex-col space-y-3">
                <button
                  onClick={() => setShowRequestModal(true)}
                  className="calm-button flex items-center justify-center space-x-2 px-6 py-3"
                >
                  <MessageCircle className="w-5 h-5" />
                  <span>Request Play</span>
                </button>
                <button
                  onClick={handleAddFriend}
                  disabled={friendRequestSent}
                  className={`flex items-center justify-center space-x-2 px-6 py-3 rounded-lg transition-colors border font-medium ${
                    friendRequestSent 
                      ? "bg-green-100 border-green-200 text-green-700" 
                      : "bg-white border-gray-300 hover:bg-gray-50 text-gray-700"
                  }`}
                >
                  {friendRequestSent ? <Check className="w-5 h-5" /> : <UserPlus className="w-5 h-5" />}
                  <span>{friendRequestSent ? "Request Sent" : "Add Friend"}</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {showRequestModal && (
        <RequestModal
          player={player}
          onClose={() => setShowRequestModal(false)}
        />
      )}
    </>
  );
}
