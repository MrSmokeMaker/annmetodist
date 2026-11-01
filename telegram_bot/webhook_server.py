"""Webhook server for Методист Pro Telegram bot.

Runs a Flask app that receives updates from Telegram and dispatches
them to the existing handler functions defined in *bot.py*.

The bot token is read from the environment variable ``BOT_TOKEN``.
"""

import os
import json
from flask import Flask, request, abort

# Import handler functions from bot.py
# It's assumed that bot.py is in the same directory and can be imported.
import bot  # noqa: E402

app = Flask(__name__)

@app.route(f"/webhook/{os.getenv('BOT_TOKEN')}", methods=["POST"])  # type: ignore[arg-type]
def webhook():
    if request.method != "POST":
        abort(405)
    try:
        update = request.get_json(force=True)
    except Exception as e:
        app.logger.error(f"Failed to parse update JSON: {e}")
        abort(400)

    # Debug log
    app.logger.debug(f"Received update: {json.dumps(update, ensure_ascii=False)}")

    # Dispatch based on update type
    if "message" in update:
        msg = update["message"]
        chat_id = msg["chat"]["id"]
        text = msg.get("text", "")
        user = msg.get("from", {})
        # Simple command routing – extend as needed
        if text.startswith("/start"):
            bot.handle_start(chat_id, user)
        elif text.startswith("/help"):
            bot.handle_help(chat_id)
        elif text.startswith("/parents"):
            # Expected format: /parents <topic>
            parts = text.split(maxsplit=1)
            topic = parts[1] if len(parts) > 1 else ""
            bot.handle_parents_chat(chat_id, topic)
        elif text.startswith("/hw"):
            parts = text.split(maxsplit=1)
            topic = parts[1] if len(parts) > 1 else ""
            bot.handle_homework_generation(chat_id, topic)
        elif text.startswith("/game"):
            parts = text.split(maxsplit=1)
            topic = parts[1] if len(parts) > 1 else ""
            bot.handle_game_generation(chat_id, topic)
        elif text.startswith("/test"):
            parts = text.split(maxsplit=1)
            topic = parts[1] if len(parts) > 1 else ""
            bot.handle_test_generation(chat_id, topic)
        elif text.startswith("/worksheet"):
            parts = text.split(maxsplit=1)
            topic = parts[1] if len(parts) > 1 else ""
            bot.handle_worksheet_generation(chat_id, topic)
        else:
            # Fallback – treat any text as free‑form request to AI
            bot.handle_text_message(chat_id, text, user)
    elif "callback_query" in update:
        cq = update["callback_query"]
        data = cq.get("data", "")
        cq_id = cq["id"]
        user_id = cq["from"]["id"]
        # Example handling for feedback – you can extend this mapping.
        if data.startswith("feedback:"):
            bot.handle_feedback(cq_id, data.split(":", 1)[1], user_id)
        else:
            bot.handle_callback_query(cq_id, data, user_id)
    else:
        app.logger.info("Unsupported update type received.")

    return "OK", 200

if __name__ == "__main__":
    # Use port from env or default 8443 (Telegram requires HTTPS).
    port = int(os.getenv("PORT", "8443"))
    # For local testing you can run with Werkzeug's built‑in server.
    # In production run behind a proper HTTPS reverse proxy.
    app.run(host="0.0.0.0", port=port, debug=False)
