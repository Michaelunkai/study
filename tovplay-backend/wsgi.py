import sys
import os

# Get the directory of the current file (wsgi.py)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Add the 'src' directory to the Python path
# This allows imports like 'from src.app import create_app' to work correctly
sys.path.insert(0, os.path.join(current_dir, 'src'))

from src.app import create_app

app = create_app()



# TODO connect frontend to port without signin to base44 (or get credentials)
# todo where are the users saved now?
# todo run to add users to db
