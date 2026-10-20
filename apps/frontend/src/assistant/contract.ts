/**
 * SafeSignal Assistant Integration Contract
 *
 * This contract establishes the strict communication protocol between the SafeSignal React
 * frontend and future FastAPI backend endpoints serving Qwen AI reasoning.
 *
 * SAFETY & PRIVACY CONSTRAINTS:
 * 1. ZERO CLIENT CREDENTIALS: Qwen API keys or model tokens MUST NOT reside in frontend code.
 * 2. NO UNVERIFIED CLAIMS: The backend assistant pipeline must never claim that a route, vehicle,
 *    or stage is officially verified as safe or unsafe unless supported by verified signals.
 * 3. NO EMERGENCY DISPATCH: Any user input with active physical threats or emergency distress
 *    must be matched with high-priority safety guidance directing the user to 999 or 112.
 * 4. ANONYMIZATION: The assistant must not store or ask for passenger phone numbers, full names,
 *    or raw payment details.
 */

export type AssistantRole = 'user' | 'assistant' | 'system'

export interface AssistantMessage {
  id: string
  role: AssistantRole
  content: string
  timestamp: number
  /**
   * Flag indicating whether the response contains critical safety guardrails
   * (e.g. advice to call 999/112).
   */
  isEmergencyNotice?: boolean
  /** Where the text came from, so the UI can label it. */
  source?: 'predefined' | 'ai' | 'fallback'
}

export interface AssistantConversationRequest {
  /**
   * Ephemeral conversation ID maintained in React state for session context.
   * Resets when user resets the conversation.
   */
  sessionId: string
  /**
   * User prompt or query text.
   */
  message: string
  /**
   * Contextual topic or intent hint if initiated from a suggested question.
   */
  topicContext?: 'reporting-guide' | 'support-options' | 'corridor-explanation' | 'general'
}

export interface AssistantConversationResponse {
  sessionId: string
  message: AssistantMessage
  /**
   * Explicit disclaimer indicating response is informational guidance.
   */
  disclaimer: string
  /**
   * Optional follow-up suggested queries for easy mobile tapping.
   */
  suggestedFollowUps?: string[]
}

/**
 * Frontend Service Interface
 */
export interface AssistantService {
  sendMessage(req: AssistantConversationRequest): Promise<AssistantConversationResponse>
  resetSession(): void
}

