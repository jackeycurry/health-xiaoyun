import { getToken } from "./api";

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface StreamCallbacks {
  /** called on every content delta */
  onChunk?: (delta: string) => void;
  /** called once the server tells us the persisted conversation id */
  onConversationId?: (id: string) => void;
  /** called once the server emits follow-up suggestions */
  onSuggestions?: (s: string[]) => void;
  /** done — full text and conversation id */
  onDone?: (full: string, conversationId?: string) => void;
  onError?: (err: unknown) => void;
}

/**
 * POST /api/consult/chat/stream with Bearer auth, parse SSE chunks.
 *
 * Backend frame format: `data: <json>\n\n`
 *   { content: "..." }                       — delta
 *   { conversation_id: "..." }               — emitted after persistence
 *   { suggestions: ["...", "..."] }          — follow-up questions
 *   [DONE]                                   — terminator
 */
export async function streamChat(
  messages: ChatMessage[],
  cb: StreamCallbacks,
  conversationId?: string,
  signal?: AbortSignal
): Promise<void> {
  const token = getToken();
  if (!token) {
    cb.onError?.(new Error("未登录"));
    return;
  }

  let full = "";
  let convoId: string | undefined = conversationId;

  try {
    const resp = await fetch("/api/consult/chat/stream", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
        Accept: "text/event-stream",
      },
      body: JSON.stringify({
        messages,
        stream: true,
        conversation_id: conversationId ?? null,
      }),
      signal,
    });

    if (!resp.ok) {
      const text = await resp.text().catch(() => `${resp.status}`);
      cb.onError?.(new Error(`HTTP ${resp.status}: ${text}`));
      return;
    }
    if (!resp.body) {
      cb.onError?.(new Error("response.body is null"));
      return;
    }

    const reader = resp.body.getReader();
    const decoder = new TextDecoder("utf-8");
    let buffer = "";

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });

      // SSE frames are separated by blank lines
      let idx: number;
      while ((idx = buffer.indexOf("\n\n")) !== -1) {
        const frame = buffer.slice(0, idx);
        buffer = buffer.slice(idx + 2);

        // each frame may have one or more `data:` lines
        for (const line of frame.split("\n")) {
          if (!line.startsWith("data:")) continue;
          const payload = line.slice(5).trim();
          if (!payload) continue;

          if (payload === "[DONE]") {
            cb.onDone?.(full, convoId);
            return;
          }

          try {
            const obj = JSON.parse(payload);
            if (typeof obj.content === "string") {
              full += obj.content;
              cb.onChunk?.(obj.content);
            } else if (typeof obj.conversation_id === "string") {
              convoId = obj.conversation_id;
              cb.onConversationId?.(obj.conversation_id);
            } else if (Array.isArray(obj.suggestions)) {
              cb.onSuggestions?.(obj.suggestions);
            }
          } catch {
            // malformed frame — skip silently
          }
        }
      }
    }

    cb.onDone?.(full, convoId);
  } catch (e) {
    if ((e as any)?.name === "AbortError") return;
    cb.onError?.(e);
  }
}
