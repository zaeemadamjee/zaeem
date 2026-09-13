import * as path from "path"
import { exec } from "child_process"
import { promisify } from "util"
import { Plugin } from "@opencode/plugin"

const execAsync = promisify(exec)

const PUSHOVER_API_URL = "https://api.pushover.net/1/messages.json"
const DEBOUNCE_MS = 5000

// Pending debounce timers keyed by sessionID
const pending = new Map()

// Cached web URL promise — resolved once at startup
let webUrlPromise = null

/**
 * Resolve the opencode web UI base URL using Tailscale MagicDNS, swapping in
 * the Tailscale hostname while preserving the port this server actually bound.
 *
 * V2 plugins no longer receive a `serverUrl` input, so the port comes from
 * `ctx.server.get()` instead (the same data backing `GET /api/server`).
 * Resolved once and cached; subsequent calls return the cached promise.
 *
 * Fallback chain: tailscale Self.DNSName → TAILSCALE_HOSTNAME env var → localhost
 */
function resolveWebUrl(ctx) {
  if (webUrlPromise) return webUrlPromise

  webUrlPromise = (async () => {
    let port = "4096"
    try {
      const { urls } = await ctx.server.get()
      const first = urls?.[0]
      if (first) port = new URL(first).port || port
    } catch {}

    try {
      const { stdout } = await execAsync("tailscale status --json")
      const status = JSON.parse(stdout)
      const dnsName = status?.Self?.DNSName?.replace(/\.$/, "") // strip trailing dot
      if (dnsName) return `http://${dnsName}:${port}`
      throw new Error("No DNSName in tailscale status")
    } catch {
      const envHost = process.env.TAILSCALE_HOSTNAME
      if (envHost) return `http://${envHost}:${port}`
      // Never return the raw bind address — its host may be 0.0.0.0.
      return `http://localhost:${port}`
    }
  })()

  return webUrlPromise
}

/**
 * Build a deep-link URL that opens the web UI directly to a specific session.
 * Format: <base>/<base64url(directory)>/session/<sessionID>
 *
 * opencode encodes the directory using URL-safe base64 (RFC 4648 §5):
 *   btoa(utf8 bytes) → replace + with -, / with _, strip = padding
 * Node's "base64url" encoding is exactly this, so we use it directly.
 * Source: packages/util/src/encode.ts in the opencode repo.
 *
 * Falls back to the base URL when directory or sessionID are unavailable.
 */
async function resolveSessionUrl(ctx, directory, sessionID) {
  const base = await resolveWebUrl(ctx)
  if (!directory || !sessionID) return base
  const dirSegment = Buffer.from(directory).toString("base64url")
  return `${base}/${dirSegment}/session/${sessionID}`
}

function clearPending(sessionID) {
  const timer = pending.get(sessionID)
  if (timer) {
    clearTimeout(timer)
    pending.delete(sessionID)
  }
}

/**
 * Create a logger that routes through opencode's app.log API.
 * Errors from the logging call itself are silently swallowed to avoid
 * recursive noise — this is a best-effort diagnostic channel.
 */
function makeLogger(ctx) {
  return async (level, message) => {
    try {
      await ctx.app.log({ body: { service: "opencode-notify", level, message } })
    } catch {}
  }
}

async function sendPushoverNotification(title, message, url, log) {
  const token = process.env.PUSHOVER_APP_TOKEN
  const user = process.env.PUSHOVER_USER_KEY

  if (!token || !user) {
    await log("error", "Missing PUSHOVER_APP_TOKEN or PUSHOVER_USER_KEY")
    return
  }

  const params = { token, user, title, message }
  if (url) {
    params.url = url
    params.url_title = "Open in browser"
  }

  try {
    const response = await fetch(PUSHOVER_API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(params).toString(),
    })
    if (!response.ok) {
      await log("error", `Pushover API error: ${response.status}`)
    }
  } catch (err) {
    await log("error", `Failed to send notification: ${err}`)
  }
}

/**
 * Dispatch a notification with per-session debouncing.
 * Rapid back-to-back signals for the same permission ask (the public event
 * stream and the permission evaluate hook can both fire) collapse into a
 * single notification.
 */
function dispatch(sessionID, title, message, url, log) {
  clearPending(sessionID)
  const timer = setTimeout(async () => {
    pending.delete(sessionID)
    await sendPushoverNotification(title, message, url, log)
  }, DEBOUNCE_MS)
  pending.set(sessionID, timer)
}

/**
 * Flush all pending debounced notifications immediately (used on process exit).
 */
async function flush() {
  const promises = []
  for (const [sessionID, timer] of pending.entries()) {
    clearTimeout(timer)
    pending.delete(sessionID)
    promises.push(timer._onFire?.())
  }
  await Promise.allSettled(promises)
}

/**
 * Normalize a message timestamp field to epoch milliseconds, whether it
 * arrives as a number, a Date, or an ISO string.
 */
function toMillis(value) {
  if (value == null) return null
  if (typeof value === "number") return value
  if (value instanceof Date) return value.getTime()
  const parsed = new Date(value).getTime()
  return Number.isNaN(parsed) ? null : parsed
}

/**
 * Enrich a notification with session context: project name, elapsed time,
 * last assistant text, subagent detection, and a deep-link web URL.
 */
async function buildNotification(ctx, directory, sessionID, eventType, fallbackMessage) {
  const projectName = directory ? path.basename(directory) : "opencode"

  let elapsedSeconds = null
  let isSubagent = false
  let assistantText = null

  try {
    if (sessionID) {
      const session = await ctx.session.get({ sessionID })
      if (session?.parentID) {
        isSubagent = true
      }

      const messages = await ctx.session.context({ sessionID })
      if (messages && messages.length > 0) {
        const firstUser = messages.find((m) => m.type === "user")
        const createdAt = toMillis(firstUser?.time?.created)
        if (createdAt !== null) {
          elapsedSeconds = Math.floor((Date.now() - createdAt) / 1000)
        }

        const lastAssistant = [...messages].reverse().find((m) => m.type === "assistant")
        if (lastAssistant?.content) {
          const textParts = lastAssistant.content.filter((p) => p.type === "text")
          const last = textParts[textParts.length - 1]
          if (last?.text?.trim()) {
            assistantText = last.text.trim()
          }
        }
      }
    }
  } catch {
    // Domain calls may fail — fall back to nulls
  }

  const resolvedType = eventType === "complete" && isSubagent ? "subagent_complete" : eventType

  const emojis = {
    complete: "\u2705",
    subagent_complete: "\u2705",
    error: "\u274c",
    permission: "\u26a0\ufe0f",
    question: "\u2753",
  }
  const emoji = emojis[resolvedType] ?? ""

  const title = `${emoji} [${resolvedType}] ${projectName}`

  let message = fallbackMessage ?? assistantText ?? "Session event"
  if (elapsedSeconds !== null) {
    const m = Math.floor(elapsedSeconds / 60)
    const s = elapsedSeconds % 60
    message += ` (${m}m ${s}s)`
  }

  const url = await resolveSessionUrl(ctx, directory, sessionID)

  return { title, message, resolvedType, url }
}

export default Plugin.define({
  id: "pushover-notify",
  async setup(ctx) {
    const directory = ctx.location.directory
    const log = makeLogger(ctx)

    if (process.env.OPENCODE_NOTIFY === "0") {
      await log("info", "Notifications disabled (OPENCODE_NOTIFY=0)")
      return
    }

    const token = process.env.PUSHOVER_APP_TOKEN
    const user = process.env.PUSHOVER_USER_KEY
    if (!token || !user) {
      await log("warn", "Missing credentials — set PUSHOVER_APP_TOKEN and PUSHOVER_USER_KEY")
    } else {
      await log("info", "Plugin loaded")
    }

    // Kick off web URL resolution eagerly so it's ready by first notification
    resolveWebUrl(ctx)

    // Flush any debounced notifications when the process is about to exit
    let flushed = false
    const flushOnExit = async () => {
      if (flushed) return
      flushed = true
      await flush()
    }
    process.on("beforeExit", flushOnExit)

    const controller = new AbortController()
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          try {
            const sessionID = event.properties?.sessionID ?? event.sessionID ?? null

            if (event.type === "session.idle") {
              const { title, message, resolvedType, url } = await buildNotification(ctx, directory, sessionID, "complete", undefined)
              if (resolvedType === "subagent_complete") continue // skip subagent completions
              dispatch(sessionID, title, message, url, log)
            } else if (event.type === "session.error") {
              const rawError = event.properties?.error ?? event.error
              const errorMessage = rawError?.data?.message ?? rawError?.message ?? rawError?.name ?? "Unknown error"
              const { title, message, url } = await buildNotification(ctx, directory, sessionID, "error", errorMessage)
              dispatch(sessionID, title, message, url, log)
            } else if (event.type === "permission.updated") {
              const { title, message, url } = await buildNotification(ctx, directory, sessionID, "permission", undefined)
              dispatch(sessionID, title, message, url, log)
            }
          } catch (err) {
            await log("error", `Event hook error: ${err}`)
          }
        }
      } catch (err) {
        if (!controller.signal.aborted) await log("error", `Event subscription error: ${err}`)
      }
    })()

    await ctx.permission.hook("evaluate", async (event) => {
      if (event.effect !== "ask") return
      try {
        const { title, message, url } = await buildNotification(ctx, directory, event.sessionID, "permission", undefined)
        dispatch(event.sessionID, title, message, url, log)
      } catch (err) {
        await log("error", `Permission evaluate hook error: ${err}`)
      }
    })

    await ctx.tool.hook("execute.before", async (event) => {
      if (event.tool !== "question") return
      try {
        const { title, message, url } = await buildNotification(ctx, directory, event.sessionID, "question", undefined)
        dispatch(event.sessionID, title, message, url, log)
      } catch (err) {
        await log("error", `Tool execute.before hook error: ${err}`)
      }
    })

    return () => {
      controller.abort()
      process.off("beforeExit", flushOnExit)
      return flushOnExit()
    }
  },
})
