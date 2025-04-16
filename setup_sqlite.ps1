# Create web/sqlite3 directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "web"

# Download sqlite3.wasm and sql-wasm.js
$baseUrl = "https://raw.githubusercontent.com/sql-js/sql.js/master/dist"
Invoke-WebRequest -Uri "$baseUrl/sql-wasm.js" -OutFile "web/sql-wasm.js"
Invoke-WebRequest -Uri "$baseUrl/sql-wasm.wasm" -OutFile "web/sql-wasm.wasm"
