from datetime import datetime, timedelta

from dotenv.main import rewrite
from flask import request, jsonify
from sqlalchemy import or_, and_

from src.app.db import db
from src.app.error_handlers import AuthorizationError
from src.app.models import ScheduledSession, User, Game, UserGamePreference, UserAvailability, GameRequest, UserProfile, \
    UserNotifications


def get_day_of_week_mapping():
    """Returns a mapping from Hebrew day names to their numeric representation (0=Sunday)."""
    return {
        "Sunday": 6, "Monday": 0, "Tuesday": 1, "Wednesday": 2,
        "Thursday": 3, "Friday": 4, "Saturday": 5
    }



def expand_availability_to_hourly_slots(availabilities):
    hourly_slots = set()
    today = datetime.now().date()
    day_mapping_rev = {v: k for k, v in get_day_of_week_mapping().items()}

    for i in range(7):
        current_date = today + timedelta(days=i)

        day_of_week_name = day_mapping_rev.get(current_date.weekday())

        for avail in availabilities:
            if avail.day_of_week == day_of_week_name:
                start = datetime.combine(current_date, avail.start_time)
                end = datetime.combine(current_date, avail.end_time)
                while start < end:
                    hourly_slots.add(start)
                    start += timedelta(hours=1)
    return hourly_slots

def expand_sessions_to_hourly_slots(sessions, hourly_slots):
    for session in sessions:
        start = datetime.combine(session.scheduled_date, session.start_time)
        end = datetime.combine(session.scheduled_date, session.end_time)
        while start < end:
            try:
                hourly_slots.remove(start)
                print(f"removed {start}")

            except:
                print(f"{start} is not in the slots. ")
            start += timedelta(hours=1)
    return hourly_slots

def match_user_availability(current_user_id, game_name):
    if not game_name:
        raise ValueError({"error": "game_name is required in the request body"})

    # print("Step 1: Find the target game and the current user's preferences")
    game = Game.query.filter_by(game_name=game_name).first()
    if not game:
        raise ValueError({"message": "Game not found"})

    # print("Step 2: Get all relevant users and their availability data in one go")
    relevant_users = db.session.query(User).join(UserGamePreference).filter(
        UserGamePreference.game_id == game.id,
        User.id != current_user_id
    ).all()

    current_user_availabilities = UserAvailability.query.filter_by(user_id=current_user_id).all()
    current_user_sessions = ScheduledSession.query.filter(
        or_(ScheduledSession.organizer_user_id == current_user_id,
            ScheduledSession.second_player_id == current_user_id)
    ).all()

    # print("Step 3: Calculate the current user's truly free time slots")
    current_user_avail_slots = expand_availability_to_hourly_slots(current_user_availabilities)
    current_user_free_slots = expand_sessions_to_hourly_slots(current_user_sessions, current_user_avail_slots)


    # print("Step 4: Find overlapping time for each relevant player")
    matches = []
    for other_user in relevant_users:
        other_user_availabilities = UserAvailability.query.filter_by(user_id=other_user.id).all()
        other_user_sessions = ScheduledSession.query.filter(
            or_(ScheduledSession.organizer_user_id == other_user.id,
                ScheduledSession.second_player_id == other_user.id)
        ).all()

        other_user_avail_slots = expand_availability_to_hourly_slots(other_user_availabilities)
        other_user_free_slots = expand_sessions_to_hourly_slots(other_user_sessions, other_user_avail_slots)


        # Find the intersection of free slots between the two users
        common_slots = current_user_free_slots.intersection(other_user_free_slots)

        if common_slots:
            # print("Step 5: Format the output for a human-readable response")
            profile = UserProfile.query.filter_by(user_id=other_user.id).first()

            match_details = {
                "id": str(other_user.id),
                "username": other_user.username,
                "discord_username": other_user.discord_username,
                "user_profile_pic": profile.avatar_url if profile else None,
                "languages": profile.language if profile else None,
                "communication_preferences": profile.communication_preferences if profile else None,
                "games": [Game.query.get_or_404(game.game_id).game_name for game in UserGamePreference.query.filter_by(user_id=other_user.id).all()],
                "available_slots": []
            }

            # Sort slots for a consistent, chronological display
            sorted_slots = sorted(list(common_slots))
            day_mapping_rev = {v: k for k, v in get_day_of_week_mapping().items()}

            for slot in sorted_slots:
                match_details["available_slots"].append({
                    "day": day_mapping_rev.get(slot.weekday()),
                    "hour": slot.strftime("%H:%M")
                })

            matches.append(match_details)
    return matches

def find_players_by_name_and_player_api(current_user_id,game_name ):
    recipient_username = request.args.get('recipient_username')
    recipient_user_id = User.query.filter_by(username=recipient_username).first().id
    game_id = Game.query.filter_by(game_name=game_name).first().id
    all_requests = []
    for req in db.session.query(GameRequest).filter(and_(
            or_(GameRequest.sender_user_id == current_user_id, GameRequest.recipient_user_id == current_user_id),
            or_(GameRequest.sender_user_id == recipient_user_id,
                GameRequest.recipient_user_id == recipient_user_id),
            GameRequest.game_id == game_id)
    ):
        all_values = req.to_dict()
        time = all_values.pop("suggested_time")
        datetime_obj = datetime.strptime(time, "%Y-%m-%d %H:%M:%S")
        weekday = datetime_obj.strftime("%A")
        time_part = datetime_obj.strftime("%H:%M")
        all_requests.append({'day': weekday, 'hour': time_part})

    return all_requests


def find_duplicate_requests(game_id, sender_user_id, recipient_user_id, suggested_time):
    return GameRequest.query.filter_by(
        game_id=game_id,
        sender_user_id=sender_user_id,
        recipient_user_id=recipient_user_id,
        suggested_time=suggested_time,
    ).first()


def create_game_request_api(sender_user_id):
    user = User.query.get(sender_user_id)
    if not user:
        return jsonify({"error": "User doesn't exist"}), 409
    data = request.get_json()
    recipient_username = data.get("recipient_username")
    recipient_user = User.query.filter_by(username=recipient_username).first()
    if not recipient_user:
        return (
            jsonify({"error": f"There is no user with the username of '{recipient_username}'"}),
            409,
        )
    game_name = data.get("game_name").title()
    game = Game.query.filter_by(game_name=game_name).first()
    if not game:
        return jsonify({"error": f"There is no game '{game_name}'"}), 409
    suggested_time = data.get("suggested_time")
    duplicate_requests = find_duplicate_requests(
        game.id, sender_user_id, recipient_user.id, suggested_time
    )
    if duplicate_requests:
        raise ValueError(
            f"A game request of '{game.game_name}' with '{user.username}' as organizer and '{recipient_username}' as a participant at {suggested_time} has already been scheduled"
        )

    new_request = GameRequest(
        sender_user_id=sender_user_id,
        recipient_user_id=recipient_user.id,
        game_id=game.id,
        suggested_time=suggested_time,
        message=data.get("message"),
    )
    print(new_request)

    recipient_notification = UserNotifications(
        user_id=recipient_user.id,
        message=f"{user.username} has invited you to play"
                f" {game_name} "
                f" at {suggested_time}",
        title="New game request"

    )
    db.session.add(recipient_notification)

    db.session.add(new_request)
    db.session.commit()
    return jsonify(new_request.to_dict()), 201

def accept_invite_api(user_id, game_request, accept_invite_bool):
    from src.api.scheduled_session_api import create_session
    request_id = game_request.id
    if not game_request:
        raise ValueError("Game request not found.")

    if str(user_id) != str(game_request.recipient_user_id) and User.query.get_or_404(user_id).role != 'Admin':

        raise AuthorizationError( f"{user_id} != {game_request.recipient_user_id}")
    if accept_invite_bool:
        print(request_id)
        session = ScheduledSession.query.filter_by(session_id=request_id).first()
        if session:
            print("Session already exists")
            status_code = 304
        elif game_request.status == "pending":
            session = create_session(
                {
                    "organizer_id": game_request.sender_user_id,
                    "second_player_id": game_request.recipient_user_id,
                    "scheduled_date": game_request.suggested_time.date(),
                    "start_time": game_request.suggested_time.time(),
                    "end_time": (game_request.suggested_time + timedelta(hours=1)).time(),
                    "game_id": game_request.game_id,
                    "session_id": game_request.id
                }
            )
            game_name = Game.query.get_or_404(game_request.game_id).game_name
            recipient_username = User.query.get_or_404(game_request.recipient_user_id).username
            sender_username = User.query.get_or_404(game_request.sender_user_id).username
            suggested_time = f"{game_request.suggested_time.date()} {game_request.suggested_time.time()}"
            print(game_name, recipient_username, sender_username, suggested_time)
            sender_message = (f"Game {game_name} "
                              f"with {recipient_username} ("
                              f"scheduled at {suggested_time}) was accepted")
            print(sender_message)
            sender_notification = UserNotifications(
                user_id=game_request.sender_user_id,
                message=sender_message,
                title="Invitation accepted"
            )
            db.session.add(sender_notification)

            recipient_notification = UserNotifications(
                user_id = game_request.recipient_user_id,
                message = f"You accepted {sender_username}'s invitation to play"
                          f" {game_name} "
                          f" at {suggested_time}",
                title="You have accepted an invitation"

            )
            db.session.add(recipient_notification)

            status_code = 201
        else:
            return None
        setattr(game_request, "status", "accepted")
        pending_requests = db.session.query(GameRequest).filter(
            and_(GameRequest.suggested_time == game_request.suggested_time),
            GameRequest.status == "pending",
            or_(
                GameRequest.sender_user_id == game_request.sender_user_id,
                GameRequest.recipient_user_id == game_request.sender_user_id,
                GameRequest.sender_user_id == game_request.recipient_user_id,
                GameRequest.recipient_user_id == game_request.recipient_user_id,
            ),
        )
        for pending_request in pending_requests:
            # call accept_invite_api with (user_id, game_request, accept_invite_bool)
            # use the pending_request.recipient_user_id as the acting user for this call
            accept_invite_api(pending_request.recipient_user_id, pending_request, False)
        db.session.commit()
        return session, status_code
    else:
        setattr(game_request, "status", "rejected")
        db.session.commit()
