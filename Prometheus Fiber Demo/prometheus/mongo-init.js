// MongoDB initialization script
// Creates test database and enables profiling

db = db.getSiblingDB('metrics_db');

// Create test collections with indexes
db.createCollection('users');
db.users.createIndex({ 'email': 1 }, { unique: true });
db.users.createIndex({ 'created_at': 1 });

db.createCollection('orders');
db.orders.createIndex({ 'user_id': 1 });
db.orders.createIndex({ 'status': 1 });

db.createCollection('products');
db.products.createIndex({ 'sku': 1 }, { unique: true });
db.products.createIndex({ 'category': 1 });

// Enable profiling (level 1 logs slow queries, level 2 logs all)
db.setProfilingLevel(1, { slowms: 100 });

// Insert sample data
db.users.insertMany([
  { email: 'user1@example.com', name: 'User One', created_at: new Date() },
  { email: 'user2@example.com', name: 'User Two', created_at: new Date() },
  { email: 'user3@example.com', name: 'User Three', created_at: new Date() }
]);

db.products.insertMany([
  { sku: 'PROD-001', name: 'Product 1', category: 'Electronics', price: 99.99 },
  { sku: 'PROD-002', name: 'Product 2', category: 'Books', price: 29.99 },
  { sku: 'PROD-003', name: 'Product 3', category: 'Electronics', price: 149.99 }
]);

print('MongoDB initialized with test collections and profiling enabled');
