/**
 * =============================================================================
 * KithLy Global Protocol - THE ORCHESTRATOR
 * orchestrator.h - Business Logic & Ingestion Interface
 * =============================================================================
 */

#pragma once

#include <string>
#include <random>

namespace Kithly {
namespace Orchestrator {

/**
 * Generates a secure 8-character token (XXXX-XXXX).
 * Excludes confusing characters ('O', '0', '1', 'I').
 * 
 * @return std::string formatted token
 */
std::string generate_handshake_token();

/**
 * Process a JSON payload from the Redis queue.
 * Performs idempotency checking and Database insertion.
 * 
 * @param raw_json The raw string from Redis brpop
 */
void process_gift_job(const std::string& raw_json);

} // namespace Orchestrator
} // namespace Kithly
