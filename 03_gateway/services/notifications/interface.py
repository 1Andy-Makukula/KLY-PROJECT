"""
KithLy Global Protocol - Notifications Interface
Standard "Send" Command Interface for notification providers.
"""

from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, List
from pydantic import BaseModel
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    STATUS_UPDATE = "status_update"
    GIFT_RECEIVED = "gift_received"
    RIDER_ASSIGNED = "rider_assigned"
    DELIVERY_COMPLETE = "delivery_complete"
    GRATITUDE_RECEIVED = "gratitude_received"


class NotificationPayload(BaseModel):
    recipient_id: str
    recipient_contact: str
    notification_type: NotificationType
    title: str
    body: str
    image_url: Optional[str] = None
    tx_id: Optional[str] = None
    metadata: Dict[str, Any] = {}


class NotificationResult(BaseModel):
    success: bool
    provider: str
    recipient: str
    message_id: Optional[str] = None
    sent_at: datetime
    error_message: Optional[str] = None


class NotificationProvider(ABC):
    @property
    @abstractmethod
    def provider_name(self) -> str:
        pass
    
    @abstractmethod
    async def send(self, payload: NotificationPayload) -> NotificationResult:
        pass


class NotificationRegistry:
    def __init__(self):
        self._providers: Dict[str, NotificationProvider] = {}
    
    def register(self, provider: NotificationProvider) -> None:
        self._providers[provider.provider_name] = provider
    
    def get(self, name: str) -> Optional[NotificationProvider]:
        return self._providers.get(name)


_registry = NotificationRegistry()

def get_registry() -> NotificationRegistry:
    return _registry
