import os
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings


@lru_cache()
def get_app_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


@lru_cache()
def get_settings():
    return Settings()


class Settings(BaseSettings):
    REDIS_IP: str = "127.0.0.1"
    REDIS_PASSWORD: str
    REDIS_PORT: int
    REDIS_DB: int = 0

    class Config:
        env_file = get_app_root() + "/app/.env"
