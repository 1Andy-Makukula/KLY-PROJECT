import os
import sys

print('Starting import test...', flush=True)
os.environ['TESTING'] = 'True'

print('1 - Importing FastAPI...', flush=True)
from fastapi import FastAPI

print('2 - Importing admin router...', flush=True)
from api.admin import router as admin_router

print('3 - Importing gifts router...', flush=True)
from api.gifts import router as gifts_router

print('4 - Importing auth router...', flush=True)
from api.auth import router as auth_router

print('5 - Importing get_redis...', flush=True)
from services.database import get_redis

print('6 - Importing app...', flush=True)
from app import app

print('Done!', flush=True)
