"""
=============================================================================
KithLy Global Protocol - PUSH NOTIFICATIONS (Phase V)
push.py - Firebase Cloud Messaging Integration
=============================================================================

Implements push notifications for:
- Re-route Found (Status 106)
- Order Ready (Status 300)
- Shop Acceptance Required (Status 110)
"""

import os
import json
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from datetime import datetime
import httpx


# =============================================================================
# CONFIGURATION
# =============================================================================

FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")
FCM_API_URL = "https://fcm.googleapis.com/fcm/send"


# =============================================================================
# NOTIFICATION TEMPLATES
# =============================================================================

@dataclass
class NotificationTemplate:
    """Push notification template"""
    title: str
    body: str
    icon: str
    color: str
    action_url: str
    priority: str = "high"


TEMPLATES = {
    # Status 106: Alternative shop found via re-routing
    "reroute_found": NotificationTemplate(
        title="Good News! 🟢",
        body="We found an alternative shop nearby. Tap to confirm.",
        icon="ic_reroute",
        color="#10B981",  # Green
        action_url="kithly://order/{tx_id}/reroute",
        priority="high"
    ),
    
    # Status 300: Order ready for collection
    "order_ready": NotificationTemplate(
        title="🎉 Your Gift is Ready!",
        body="Your order at {shop_name} is ready for collection.",
        icon="ic_gift",
        color="#F85A47",  # Primary Orange
        action_url="kithly://order/{tx_id}/collection",
        priority="high"
    ),
    
    # Status 110: Shop acceptance required (Baker's Protocol)
    "acceptance_required": NotificationTemplate(
        title="New Order Request 🔔",
        body="You have a new custom order request from {customer_name}.",
        icon="ic_order",
        color="#DAA520",  # Gold
        action_url="kithly://shop/orders/{tx_id}/accept",
        priority="high"
    ),
    
    # Order declined - refund initiated
    "order_declined": NotificationTemplate(
        title="Order Update",
        body="Unfortunately, {shop_name} couldn't fulfill your order. Full refund initiated.",
        icon="ic_refund",
        color="#EF4444",  # Red
        action_url="kithly://order/{tx_id}/status",
        priority="normal"
    ),
    
    # Delivery dispatched
    "delivery_dispatched": NotificationTemplate(
        title="🚴 On the Way!",
        body="Your gift is being delivered. Track: {tracking_link}",
        icon="ic_delivery",
        color="#3B82F6",  # Blue
        action_url="kithly://order/{tx_id}/track",
        priority="high"
    ),
}


# =============================================================================
# PUSH SERVICE
# =============================================================================

class PushNotificationService:
    """Firebase Cloud Messaging notification service."""
    
    def __init__(self, server_key: Optional[str] = None):
        self.server_key = server_key or FCM_SERVER_KEY
        self.enabled = bool(self.server_key)
    
    async def send(
        self,
        token: str,
        template_key: str,
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Send push notification to a device.
        
        Args:
            token: FCM device token
            template_key: Key from TEMPLATES dict
            data: Template variable substitutions
        
        Returns:
            FCM response or error dict
        """
        if not self.enabled:
            return {"success": False, "error": "FCM not configured"}
        
        template = TEMPLATES.get(template_key)
        if not template:
            return {"success": False, "error": f"Unknown template: {template_key}"}
        
        data = data or {}
        
        # Format template strings
        title = template.title.format(**data)
        body = template.body.format(**data)
        action_url = template.action_url.format(**data)
        
        payload = {
            "to": token,
            "priority": template.priority,
            "notification": {
                "title": title,
                "body": body,
                "icon": template.icon,
                "color": template.color,
                "click_action": action_url,
                "sound": "default",
            },
            "data": {
                "template": template_key,
                "action_url": action_url,
                "timestamp": datetime.utcnow().isoformat(),
                **data
            }
        }
        
        return await self._send_fcm(payload)
    
    async def send_to_topic(
        self,
        topic: str,
        template_key: str,
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Send notification to all subscribers of a topic."""
        if not self.enabled:
            return {"success": False, "error": "FCM not configured"}
        
        template = TEMPLATES.get(template_key)
        if not template:
            return {"success": False, "error": f"Unknown template: {template_key}"}
        
        data = data or {}
        
        payload = {
            "to": f"/topics/{topic}",
            "priority": template.priority,
            "notification": {
                "title": template.title.format(**data),
                "body": template.body.format(**data),
                "icon": template.icon,
                "color": template.color,
            },
            "data": {
                "template": template_key,
                **data
            }
        }
        
        return await self._send_fcm(payload)
    
    async def send_multicast(
        self,
        tokens: List[str],
        template_key: str,
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Send to multiple devices at once (max 500)."""
        if not self.enabled:
            return {"success": False, "error": "FCM not configured"}
        
        if len(tokens) > 500:
            tokens = tokens[:500]
        
        template = TEMPLATES.get(template_key)
        if not template:
            return {"success": False, "error": f"Unknown template: {template_key}"}
        
        data = data or {}
        
        payload = {
            "registration_ids": tokens,
            "priority": template.priority,
            "notification": {
                "title": template.title.format(**data),
                "body": template.body.format(**data),
                "icon": template.icon,
                "color": template.color,
            },
            "data": {
                "template": template_key,
                **data
            }
        }
        
        return await self._send_fcm(payload)
    
    async def _send_fcm(self, payload: Dict) -> Dict[str, Any]:
        """Send request to FCM API."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    FCM_API_URL,
                    json=payload,
                    headers={
                        "Authorization": f"key={self.server_key}",
                        "Content-Type": "application/json"
                    },
                    timeout=10.0
                )
                
                result = response.json()
                
                return {
                    "success": result.get("success", 0) > 0,
                    "message_id": result.get("results", [{}])[0].get("message_id"),
                    "failure": result.get("failure", 0),
                    "raw_response": result
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }


# =============================================================================
# STATUS CHANGE TRIGGERS
# =============================================================================

async def on_status_change(
    tx_id: str,
    new_status: int,
    user_token: str,
    context: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Trigger appropriate push notification based on status change.
    
    Args:
        tx_id: Transaction ID
        new_status: New status code
        user_token: FCM token of the user to notify
        context: Additional context (shop_name, customer_name, etc.)
    """
    push = PushNotificationService()
    
    template_map = {
        106: "reroute_found",       # ALT_FOUND
        110: "acceptance_required", # AWAITING_SHOP_ACCEPTANCE
        300: "order_ready",         # READY_FOR_COLLECTION
        910: "order_declined",      # DECLINED
    }
    
    template_key = template_map.get(new_status)
    if not template_key:
        return {"success": False, "error": f"No notification for status {new_status}"}
    
    data = {"tx_id": tx_id, **context}
    
    return await push.send(user_token, template_key, data)


async def send_reroute_notification(tx_id: str, user_token: str, shop_name: str, distance_diff: str):
    """
    Send notification when re-route is found (Status 106).
    Called by orchestrator when alternative shop is found.
    """
    push = PushNotificationService()
    return await push.send(
        token=user_token,
        template_key="reroute_found",
        data={
            "tx_id": tx_id,
            "shop_name": shop_name,
            "distance_diff": distance_diff
        }
    )


async def send_baker_notification(tx_id: str, shop_token: str, customer_name: str, product_name: str):
    """
    Send notification to shop for new custom order (Status 110).
    """
    push = PushNotificationService()
    return await push.send(
        token=shop_token,
        template_key="acceptance_required",
        data={
            "tx_id": tx_id,
            "customer_name": customer_name,
            "product_name": product_name
        }
    )


# =============================================================================
# SINGLETON
# =============================================================================

_push_service: Optional[PushNotificationService] = None

def get_push_service() -> PushNotificationService:
    """Get singleton push service."""
    global _push_service
    if _push_service is None:
        _push_service = PushNotificationService()
    return _push_service
