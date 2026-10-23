import { WutzupError, identifier, language, objectInput, text } from "./index";

export interface WutzupUser {
  id: string;
  displayName: string;
  email?: string;
  isTutor: boolean;
  createdAt: string;
  lastSeen?: string;
  profileImageUrl?: string | null;
  personality?: string | null;
  primaryLanguageCode?: string | null;
  learningLanguageCode?: string | null;
}
export interface WutzupConversation {
  id: string;
  participantIds: string[];
  participantNames: Record<string, string>;
  isGroup: boolean;
  groupName?: string | null;
  groupImageUrl?: string | null;
  lastMessage?: string;
  lastMessageTimestamp?: string;
  createdAt: string;
  updatedAt: string;
  unreadCount: number;
  revision: number;
}
export interface WutzupMessage {
  id: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  content: string;
  timestamp: string;
  status: "sent" | "delivered" | "read";
  readBy: string[];
  deliveredTo: string[];
  mediaUrl?: string | null;
  mediaType?: string | null;
  language?: string | null;
  isFromCurrentUser: boolean;
}
export const WUTZUP_DATA_ACTIONS = [
  "bootstrap",
  "users",
  "user",
  "profile",
  "delete_account",
  "conversations",
  "create_conversation",
  "conversation",
  "update_conversation",
  "add_members",
  "send_message",
  "messages",
  "sync_messages",
  "receipts",
  "presence_set",
  "presence",
  "typing_set",
  "typing",
  "device_register",
  "device_unregister",
] as const;
export type WutzupDataAction = (typeof WUTZUP_DATA_ACTIONS)[number];

function boolean(value: unknown, name: string): boolean {
  if (typeof value !== "boolean") throw new WutzupError(`invalid_${name}`);
  return value;
}
function integer(value: unknown, name: string, max: number): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < 1 ||
    value > max
  )
    throw new WutzupError(`invalid_${name}`);
  return value;
}
function ids(value: unknown, name: string, min: number, max: number): string[] {
  if (!Array.isArray(value) || value.length < min || value.length > max)
    throw new WutzupError(`invalid_${name}`);
  const values = value.map((x) => identifier(x, name));
  if (new Set(values).size !== values.length)
    throw new WutzupError(`invalid_${name}`);
  return values;
}
function cursor(value: unknown): { at: string; id: string } {
  const v = objectInput(value);
  const at = text(v.at, "cursor", 40);
  if (!/^\d{4}-\d\d-\d\dT/.test(at) || !Number.isFinite(Date.parse(at)))
    throw new WutzupError("invalid_cursor");
  return { at, id: v.id === "" ? "" : identifier(v.id, "cursor") };
}
export function mediaURL(value: unknown): string | null {
  if (value === null) return null;
  const raw = text(value, "media_url", 1000);
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new WutzupError("invalid_media_url");
  }
  if (
    url.protocol !== "https:" ||
    !["api.archlife.org", "api-dev.archlife.org", "api-dev.archlife"].includes(
      url.hostname,
    ) ||
    url.username ||
    url.password ||
    url.search ||
    url.hash ||
    (url.port &&
      !(url.hostname === "api-dev.archlife" && url.port === "18443")) ||
    !/^\/api\/wutzup\/media\/[a-f0-9]{64}\/[A-Za-z0-9_-]{43}$/.test(
      url.pathname,
    )
  )
    throw new WutzupError("invalid_media_url");
  return raw;
}
/** Strict action allowlist is separate from the private SQL worker/AI/import lanes. */
export function validateDataAction(
  action: string,
  value: unknown,
): Record<string, unknown> {
  if (!WUTZUP_DATA_ACTIONS.includes(action as WutzupDataAction))
    throw new WutzupError("unknown_action", 404);
  const v = objectInput(value),
    out: Record<string, unknown> = {};
  const fields: Record<string, string[]> = {
    bootstrap: ["displayName"],
    users: ["isTutor", "limit", "after"],
    user: ["id"],
    profile: [
      "displayName",
      "personality",
      "profileImageUrl",
      "primaryLanguageCode",
      "learningLanguageCode",
    ],
    delete_account: [],
    conversations: ["limit", "after"],
    create_conversation: ["id", "participantIds", "isGroup", "groupName"],
    conversation: ["conversationId"],
    add_members: ["conversationId", "participantIds"],
    update_conversation: [
      "conversationId",
      "revision",
      "participantIds",
      "groupName",
      "groupImageUrl",
    ],
    send_message: [
      "conversationId",
      "id",
      "content",
      "mediaUrl",
      "mediaType",
      "language",
    ],
    messages: ["conversationId", "limit", "before"],
    sync_messages: ["conversationId", "limit", "cursor"],
    receipts: ["conversationId", "ids", "kind"],
    presence_set: ["status"],
    presence: ["id"],
    typing_set: ["conversationId", "isTyping"],
    typing: ["conversationId"],
    device_register: ["token", "environment"],
    device_unregister: ["token"],
  };
  if (Object.keys(v).some((k) => !fields[action].includes(k)))
    throw new WutzupError("unexpected_field");
  for (const k of fields[action])
    if (v[k] !== undefined) {
      if (["id", "conversationId", "after"].includes(k))
        out[k] = identifier(v[k], k);
      else if (k === "participantIds" || k === "ids")
        out[k] = ids(
          v[k],
          k,
          k === "ids" || action === "add_members" ? 1 : 2,
          k === "ids" ? 200 : 100,
        );
      else if (["isGroup", "isTutor", "isTyping"].includes(k))
        out[k] = boolean(v[k], k);
      else if (k === "limit" || k === "revision")
        out[k] = integer(v[k], k, k === "limit" ? 200 : 2147483647);
      else if (["cursor", "before"].includes(k)) out[k] = cursor(v[k]);
      else if (["mediaUrl", "profileImageUrl", "groupImageUrl"].includes(k))
        out[k] = mediaURL(v[k]);
      else if (
        ["primaryLanguageCode", "learningLanguageCode", "language"].includes(k)
      )
        out[k] = v[k] === null ? null : language(v[k]);
      else if (["personality", "groupName"].includes(k))
        out[k] =
          v[k] === null
            ? null
            : typeof v[k] === "string" && !v[k].trim()
              ? null
              : text(v[k], k, k === "personality" ? 4000 : 256);
      else
        out[k] = text(
          v[k],
          k,
          k === "content" ? 10000 : k === "displayName" ? 256 : 256,
        );
    }
  const required: Record<string, string[]> = {
    bootstrap: ["displayName"],
    user: ["id"],
    create_conversation: ["id", "participantIds", "isGroup"],
    conversation: ["conversationId"],
    add_members: ["conversationId", "participantIds"],
    update_conversation: ["conversationId", "revision"],
    send_message: ["conversationId", "id", "content"],
    messages: ["conversationId"],
    sync_messages: ["conversationId"],
    receipts: ["conversationId", "ids", "kind"],
    presence_set: ["status"],
    presence: ["id"],
    typing_set: ["conversationId", "isTyping"],
    typing: ["conversationId"],
    device_register: ["token", "environment"],
    device_unregister: ["token"],
  };
  if ((required[action] || []).some((k) => out[k] === undefined))
    throw new WutzupError("missing_field");
  if (
    out.kind !== undefined &&
    !["read", "delivered"].includes(out.kind as string)
  )
    throw new WutzupError("invalid_receipts");
  if (
    out.status !== undefined &&
    !["online", "offline", "away"].includes(out.status as string)
  )
    throw new WutzupError("invalid_presence");
  if (
    out.environment !== undefined &&
    !["sandbox", "production"].includes(out.environment as string)
  )
    throw new WutzupError("invalid_device");
  if (
    out.token !== undefined &&
    !/^[a-f0-9]{64,256}$/.test(out.token as string)
  )
    throw new WutzupError("invalid_device");
  if (
    out.mediaType !== undefined &&
    !["image", "gif", "research"].includes(out.mediaType as string)
  )
    throw new WutzupError("invalid_media_type");
  return out;
}
