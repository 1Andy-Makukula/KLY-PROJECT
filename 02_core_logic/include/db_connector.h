/**
 * =============================================================================
 * KithLy Global Protocol - THE BRIDGE
 * db_connector.h - PostgreSQL Connection Interface
 * =============================================================================
 */

#pragma once

#include <string>

namespace Kithly {

/**
 * Update the status_code for a transaction in Global_Gifts
 * 
 * @param uuid The transaction UUID
 * @param new_status The new status code (100, 200, 250, 300, 400)
 * @return true if update was successful, false otherwise
 */
bool update_status(const std::string& uuid, int new_status);

/**
 * Initialize database connection
 * Uses environment variables or defaults to local 'kithly' database
 */
bool init_db_connection();

/**
 * Close database connection
 */
void close_db_connection();

} // namespace Kithly
