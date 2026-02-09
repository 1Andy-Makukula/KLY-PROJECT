"""
KithLy Global Protocol - Console Mock Notification Provider
Terminal testing for notifications.
"""

from datetime import datetime
from typing import List
from .interface import NotificationProvider, NotificationPayload, NotificationResult


class ConsoleMockProvider(NotificationProvider):
    """Mock provider that prints to console."""
    
    @property
    def provider_name(self) -> str:
        return "console_mock"
    
    async def send(self, payload: NotificationPayload) -> NotificationResult:
        print(f"\n{'='*50}")
        print(f"📬 NOTIFICATION [{payload.notification_type.value}]")
        print(f"To: {payload.recipient_contact}")
        print(f"Title: {payload.title}")
        print(f"Body: {payload.body}")
        if payload.tx_id:
            print(f"TX: {payload.tx_id}")
        print(f"{'='*50}\n")
        
        return NotificationResult(
            success=True,
            provider=self.provider_name,
            recipient=payload.recipient_contact,
            message_id=f"mock_{datetime.utcnow().timestamp()}",
            sent_at=datetime.utcnow()
        )
