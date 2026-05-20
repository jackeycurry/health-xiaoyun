import { marked } from "marked";
import DOMPurify from "dompurify";

/**
 * Render markdown → sanitized HTML.
 *
 * Notes for streaming use:
 *  - Called on every typewriter frame, so it must be cheap. marked + DOMPurify
 *    over a ~500-char string is well under 1ms on modern hardware.
 *  - marked itself ignores unclosed inline markers (a trailing `**` won't
 *    suddenly become <strong>), so partial output during typewriter is safe.
 *  - Raw HTML in the source still survives marked; DOMPurify is what actually
 *    keeps a malicious assistant response (or a future tool that echoes user
 *    text) from injecting <script>.
 */
marked.setOptions({
  gfm: true,
  breaks: true,
});

export function renderMarkdown(src: string): string {
  if (!src) return "";
  const raw = marked.parse(src, { async: false }) as string;
  return DOMPurify.sanitize(raw, {
    ADD_ATTR: ["target", "rel"],
    FORBID_TAGS: ["style", "script", "iframe", "form", "input", "button"],
  });
}
