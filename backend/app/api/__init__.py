from flask import Blueprint

api = Blueprint('api', __name__)

from . import routes
from . import trips
from . import auth
from . import ai