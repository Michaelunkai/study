"""
Example of how to use the robust error handling system in routes.
This demonstrates best practices for database operations with proper error handling.
"""

from flask import Blueprint, jsonify, request
from sqlalchemy.exc import SQLAlchemyError

from ..db import db
from ..models import User, Game, GameRequest
from ..error_handlers import (
    with_db_error_handling, 
    with_transaction,
    ValidationError,
    AuthenticationError,
    TovPlayError
)
from ..db_utils import (
    get_or_404,
    create_record,
    update_record,
    delete_record,
    paginated_query,
    transaction,
    safe_query_all,
    DatabaseHealthChecker
)

# Example blueprint showing safe database operations
safe_routes_bp = Blueprint('safe_examples', __name__, url_prefix='/api/safe')


@safe_routes_bp.route('/users', methods=['GET'])
@with_db_error_handling
def get_users():
    """
    Get all users with pagination and error handling.
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)
    
    # Use safe pagination that handles database errors
    pagination = paginated_query(
        User.query.order_by(User.created_at.desc()),
        page=page,
        per_page=per_page
    )
    
    users_data = []
    for user in pagination.items:
        users_data.append({
            'id': str(user.id),
            'username': user.username,
            'email': user.email,
            'created_at': user.created_at.isoformat() if user.created_at else None
        })
    
    return jsonify({
        'users': users_data,
        'pagination': {
            'page': pagination.page,
            'per_page': pagination.per_page,
            'total': pagination.total,
            'pages': pagination.pages,
            'has_next': pagination.has_next,
            'has_prev': pagination.has_prev
        }
    })


@safe_routes_bp.route('/users/<user_id>', methods=['GET'])
@with_db_error_handling
def get_user(user_id):
    """
    Get a specific user with proper error handling.
    """
    # This will automatically return 404 if user not found
    user = get_or_404(User, id=user_id)
    
    return jsonify({
        'id': str(user.id),
        'username': user.username,
        'email': user.email,
        'discord_username': user.discord_username,
        'verified': user.verified,
        'created_at': user.created_at.isoformat() if user.created_at else None
    })


@safe_routes_bp.route('/users', methods=['POST'])
@with_db_error_handling
@transaction
def create_user():
    """
    Create a new user with validation and error handling.
    """
    data = request.get_json()
    
    if not data:
        raise ValidationError("Request body is required")
    
    # Validate required fields
    required_fields = ['username', 'email', 'discord_username', 'password']
    for field in required_fields:
        if not data.get(field):
            raise ValidationError(f"{field} is required", field=field)
    
    # Additional validation
    if len(data['username']) < 3:
        raise ValidationError("Username must be at least 3 characters", field='username')
    
    if '@' not in data['email']:
        raise ValidationError("Invalid email format", field='email')
    
    # Check for existing users (this will handle unique constraint errors)
    existing_user = User.query.filter(
        (User.email == data['email']) | (User.username == data['username'])
    ).first()
    
    if existing_user:
        if existing_user.email == data['email']:
            raise ValidationError("Email already exists", field='email')
        else:
            raise ValidationError("Username already exists", field='username')
    
    # Hash password (in a real app, use proper password hashing)
    import bcrypt
    hashed_password = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())
    
    # Create user using safe database operations
    user = create_record(
        User,
        username=data['username'],
        email=data['email'],
        discord_username=data['discord_username'],
        hashed_password=hashed_password.decode('utf-8')
    )
    
    return jsonify({
        'id': str(user.id),
        'username': user.username,
        'email': user.email,
        'message': 'User created successfully'
    }), 201


@safe_routes_bp.route('/users/<user_id>', methods=['PUT'])
@with_db_error_handling
@transaction
def update_user(user_id):
    """
    Update a user with proper validation and error handling.
    """
    data = request.get_json()
    
    if not data:
        raise ValidationError("Request body is required")
    
    # Get user or return 404
    user = get_or_404(User, id=user_id)
    
    # Validate updatable fields
    updatable_fields = ['username', 'discord_username']
    update_data = {}
    
    for field in updatable_fields:
        if field in data:
            value = data[field]
            if not value or not isinstance(value, str):
                raise ValidationError(f"Invalid {field}", field=field)
            update_data[field] = value
    
    # Check for conflicts with existing users
    if 'username' in update_data:
        existing = User.query.filter(
            User.username == update_data['username'],
            User.id != user.id
        ).first()
        
        if existing:
            raise ValidationError("Username already exists", field='username')
    
    if not update_data:
        raise ValidationError("No valid fields to update")
    
    # Update user using safe operations
    updated_user = update_record(user, **update_data)
    
    return jsonify({
        'id': str(updated_user.id),
        'username': updated_user.username,
        'discord_username': updated_user.discord_username,
        'message': 'User updated successfully'
    })


@safe_routes_bp.route('/users/<user_id>', methods=['DELETE'])
@with_db_error_handling
@transaction
def delete_user(user_id):
    """
    Delete a user with proper error handling.
    """
    # Get user or return 404
    user = get_or_404(User, id=user_id)
    
    # Check if user has active game requests
    active_requests = GameRequest.query.filter(
        (GameRequest.sender_user_id == user.id) | (GameRequest.recipient_user_id == user.id),
        GameRequest.status == 'pending'
    ).count()
    
    if active_requests > 0:
        raise ValidationError(
            f"Cannot delete user with {active_requests} active game requests. Cancel them first."
        )
    
    # Safe delete operation
    delete_record(user)
    
    return jsonify({
        'message': 'User deleted successfully'
    }), 204


@safe_routes_bp.route('/health-check', methods=['GET'])
@with_db_error_handling
def database_health_check():
    """
    Perform a comprehensive database health check.
    """
    with DatabaseHealthChecker():
        # Test basic operations
        user_count = safe_query_all(User.query.limit(1))
        game_count = safe_query_all(Game.query.limit(1))
        
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'basic_operations': 'working',
            'sample_data': {
                'users_available': len(user_count) > 0,
                'games_available': len(game_count) > 0
            }
        })


@safe_routes_bp.route('/test-error/<error_type>', methods=['GET'])
def test_error_handling(error_type):
    """
    Test different types of errors for development/testing purposes.
    """
    if error_type == 'validation':
        raise ValidationError("This is a test validation error", field='test_field')
    
    elif error_type == 'auth':
        raise AuthenticationError("This is a test authentication error")
    
    elif error_type == 'not_found':
        raise TovPlayError("This is a test not found error", status_code=404)
    
    elif error_type == 'db_error':
        # Force a database error
        from sqlalchemy import text
        db.session.execute(text("SELECT * FROM nonexistent_table"))
    
    elif error_type == 'generic':
        raise Exception("This is a test generic error")
    
    else:
        return jsonify({'message': 'Unknown error type', 'available_types': [
            'validation', 'auth', 'not_found', 'db_error', 'generic'
        ]}), 400


# Usage examples in comments:

"""
Example API calls and expected responses:

1. Get users with pagination:
   GET /api/safe/users?page=1&per_page=10
   
2. Get specific user:
   GET /api/safe/users/123e4567-e89b-12d3-a456-426614174000
   Response: 404 if not found, 200 with user data if found
   
3. Create user with validation:
   POST /api/safe/users
   Body: {"username": "john", "email": "john@example.com", "discord_username": "john#1234", "password": "secret"}
   Response: 400 for validation errors, 409 for conflicts, 201 for success
   
4. Update user:
   PUT /api/safe/users/123e4567-e89b-12d3-a456-426614174000
   Body: {"username": "john_updated"}
   Response: 404 if not found, 400 for validation errors, 200 for success
   
5. Delete user:
   DELETE /api/safe/users/123e4567-e89b-12d3-a456-426614174000
   Response: 404 if not found, 400 if has dependencies, 204 for success

All errors return consistent JSON format:
{
  "error": "Error message",
  "type": "error_type",
  "status_code": 400,
  "timestamp": "2024-01-09T12:00:00Z",
  "field": "field_name" // for validation errors
}
"""