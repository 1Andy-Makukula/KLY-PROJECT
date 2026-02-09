/**
 * =============================================================================
 * KithLy Global Protocol - THE BRIDGE
 * db_connector.cpp - PostgreSQL Connection Implementation
 * =============================================================================
 */

#include "db_connector.h"
#include <libpq-fe.h>
#include <iostream>
#include <cstdlib>

namespace Kithly {

// Global connection handle
static PGconn* conn = nullptr;

bool init_db_connection() {
    // Build connection string from environment or defaults
    const char* host = std::getenv("KITHLY_DB_HOST");
    const char* port = std::getenv("KITHLY_DB_PORT");
    const char* dbname = std::getenv("KITHLY_DB_NAME");
    const char* user = std::getenv("KITHLY_DB_USER");
    const char* password = std::getenv("KITHLY_DB_PASSWORD");
    
    std::string conninfo = "dbname=";
    conninfo += (dbname ? dbname : "kithly");
    conninfo += " host=";
    conninfo += (host ? host : "localhost");
    conninfo += " port=";
    conninfo += (port ? port : "5432");
    if (user) {
        conninfo += " user=";
        conninfo += user;
    }
    if (password) {
        conninfo += " password=";
        conninfo += password;
    }
    
    conn = PQconnectdb(conninfo.c_str());
    
    if (PQstatus(conn) != CONNECTION_OK) {
        std::cerr << "[KITHLY] Database connection failed: " 
                  << PQerrorMessage(conn) << std::endl;
        PQfinish(conn);
        conn = nullptr;
        return false;
    }
    
    std::cout << "[KITHLY] Connected to database: " 
              << (dbname ? dbname : "kithly") << std::endl;
    return true;
}

void close_db_connection() {
    if (conn) {
        PQfinish(conn);
        conn = nullptr;
        std::cout << "[KITHLY] Database connection closed." << std::endl;
    }
}

bool update_status(const std::string& uuid, int new_status) {
    if (!conn) {
        std::cerr << "[KITHLY] No database connection." << std::endl;
        return false;
    }
    
    // Prepare the UPDATE query
    const char* query = 
        "UPDATE Global_Gifts SET status_code = $1 WHERE tx_id = $2";
    
    // Convert parameters to C strings
    std::string status_str = std::to_string(new_status);
    const char* paramValues[2] = { status_str.c_str(), uuid.c_str() };
    
    // Execute parameterized query (prevents SQL injection)
    PGresult* res = PQexecParams(
        conn,
        query,
        2,           // number of parameters
        nullptr,     // let backend deduce param types
        paramValues,
        nullptr,     // param lengths (text format doesn't need this)
        nullptr,     // param formats (0 = text)
        0            // result format (0 = text)
    );
    
    if (PQresultStatus(res) != PGRES_COMMAND_OK) {
        std::cerr << "[KITHLY] UPDATE failed: " 
                  << PQerrorMessage(conn) << std::endl;
        PQclear(res);
        return false;
    }
    
    // Check if any row was actually updated
    int rows_affected = std::atoi(PQcmdTuples(res));
    PQclear(res);
    
    if (rows_affected == 0) {
        std::cerr << "[KITHLY] No transaction found with UUID: " 
                  << uuid << std::endl;
        return false;
    }
    
    std::cout << "[KITHLY] Status updated to " << new_status 
              << " for tx_id: " << uuid << std::endl;
    return true;
}

} // namespace Kithly
