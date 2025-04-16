// SQLite initialization script
self.sqlite3InitModule = function() {
  return initSqlite3({
    locateFile: file => `/sqlite3/${file}`
  });
}; 