// MongoDB initialization script
// Creates a read-only user for the MongoDB exporter

db = db.getSiblingDB('admin');

db.createUser({
  user: 'mongoexporter',
  pwd: 'exporterpassword',
  roles: [
    { role: 'clusterMonitor', db: 'admin' },
    { role: 'read', db: 'local' },
    { role: 'readAnyDatabase', db: 'admin' },
  ]
});

// Create sample app database and collections for testing
db = db.getSiblingDB('appdb');

db.createCollection('events');
db.createCollection('users');

print('MongoDB initialization complete. Exporter user created.');