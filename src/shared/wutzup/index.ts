/** Firebase identity and wire contracts for the native Wutzup client. */
export * from "./data";
export const WUTZUP_OPERATIONS = [
  "generate_response_suggestions",
  "translate_text",
  "message_context",
  "language_tutor",
  "conduct_research",
  "generate_gif",
  "generate_tutor_greeting",
  "generate_tutor_response",
] as const;
export type WutzupOperation = (typeof WUTZUP_OPERATIONS)[number];
export type WutzupResult = Record<string, unknown>;
export interface WutzupHistoryEntry {
  content: string;
  sender_id?: string;
  sender_name?: string;
  timestamp?: string;
  is_from_current_user?: boolean;
  role?: "user" | "assistant";
}
export interface WutzupSuggestions {
  positive_response: string;
  negative_response: string;
}
export interface WutzupTranslation {
  translated_text: string;
  detected_language: string;
}
export interface WutzupSource {
  title: string;
  url: string;
}
export class WutzupError extends Error {
  constructor(
    public code: string,
    public status = 400,
  ) {
    super(code);
  }
}
export function objectInput(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new WutzupError("invalid_body");
  return value as Record<string, unknown>;
}
export function text(value: unknown, field: string, max = 10000): string {
  if (typeof value !== "string" || !value.trim() || value.length > max)
    throw new WutzupError(`invalid_${field}`);
  return value.trim();
}
export function identifier(value: unknown, field: string): string {
  const result = text(value, field, 128);
  if (!/^[A-Za-z0-9_-]+$/.test(result))
    throw new WutzupError(`invalid_${field}`);
  return result;
}
export function language(value: unknown, fallback?: string): string {
  if (value === undefined && fallback) return fallback;
  const result = text(value, "language", 35);
  if (!/^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/.test(result))
    throw new WutzupError("invalid_language");
  return result;
}
export function history(
  value: unknown,
  required = false,
): WutzupHistoryEntry[] {
  if (value === undefined && !required) return [];
  if (!Array.isArray(value) || value.length > 50 || (required && !value.length))
    throw new WutzupError("invalid_conversation_history");
  return value
    .map((entry) => {
      const item = objectInput(entry);
      const result: WutzupHistoryEntry = {
        content: text(item.content, "history_content", 10000),
      };
      for (const name of ["sender_id", "sender_name", "timestamp"] as const) {
        if (item[name] !== undefined)
          result[name] = text(
            item[name],
            name,
            name === "timestamp" ? 100 : 256,
          );
      }
      if (item.is_from_current_user !== undefined) {
        if (typeof item.is_from_current_user !== "boolean")
          throw new WutzupError("invalid_history_actor");
        result.is_from_current_user = item.is_from_current_user;
      }
      if (item.role !== undefined) {
        if (item.role !== "user" && item.role !== "assistant")
          throw new WutzupError("invalid_history_role");
        result.role = item.role;
      }
      return result;
    })
    .slice(-10);
}
