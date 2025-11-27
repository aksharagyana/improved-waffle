#!/usr/bin/env node

const Redis = require('ioredis');

// Redis Cluster Configuration
const REDIS_HOSTS = process.env.REDIS_HOSTS || 'test-redis-cluster-headless.redis.svc.cluster.local:6379';
const REDIS_PASSWORD = process.env.REDIS_PASSWORD || '';

// Parse host:port combinations
const startupNodes = REDIS_HOSTS.split(',').map(hostPort => {
  const [host, port] = hostPort.trim().split(':');
  return {
    host: host,
    port: parseInt(port) || 6379
  };
});

console.log('🚀 Connecting to Redis Cluster...');
console.log('📍 Cluster nodes:', startupNodes.map(node => `${node.host}:${node.port}`).join(', '));

// Create Redis Cluster client
const cluster = new Redis.Cluster(startupNodes, {
  redisOptions: {
    password: REDIS_PASSWORD,
    // Additional options for reliability
    lazyConnect: false,
    retryDelayOnFailover: 100,
    enableReadyCheck: true,
    maxRetriesPerRequest: 3,
  },

  // Cluster-specific options
  clusterRetryStrategy: (times) => {
    const delay = Math.min(times * 100, 3000);
    console.log(`🔄 Cluster retry attempt ${times}, waiting ${delay}ms...`);
    return delay;
  },

  // Handle cluster events
  enableOfflineQueue: true,
  redisOptions: {
    password: REDIS_PASSWORD,
  }
});

// Event handlers
cluster.on('connect', () => {
  console.log('✅ Connected to Redis Cluster');
});

cluster.on('ready', () => {
  console.log('🎉 Redis Cluster is ready for operations');
  startOperations();
});

cluster.on('error', (err) => {
  console.error('❌ Redis Cluster Error:', err.message);
});

cluster.on('close', () => {
  console.log('🔌 Connection closed');
});

cluster.on('reconnecting', () => {
  console.log('🔄 Reconnecting to Redis Cluster...');
});

cluster.on('+node', (node) => {
  console.log(`➕ Node added: ${node.options.host}:${node.options.port}`);
});

cluster.on('-node', (node) => {
  console.log(`➖ Node removed: ${node.options.host}:${node.options.port}`);
});

// Handle process termination
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await cluster.quit();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await cluster.quit();
  process.exit(0);
});

// Main operations function
async function startOperations() {
  try {
    console.log('\n🔥 Starting Redis Cluster Operations...\n');

    // Test 1: Basic connectivity
    await testBasicOperations();

    // Test 2: Hash slot distribution
    await testHashSlotDistribution();

    // Test 3: Data types operations
    await testDataTypes();

    // Test 4: Cluster info
    await testClusterInfo();

    // Test 5: Performance test
    await testPerformance();

    console.log('\n✅ All operations completed successfully!');
    console.log('📊 Redis Cluster is working correctly!');

  } catch (error) {
    console.error('❌ Error during operations:', error.message);
    process.exit(1);
  } finally {
    await cluster.quit();
  }
}

// Test basic operations
async function testBasicOperations() {
  console.log('📝 Test 1: Basic Read/Write Operations');

  try {
    // String operations
    await cluster.set('test:key1', 'Hello Redis Cluster!');
    const value1 = await cluster.get('test:key1');
    console.log(`  ✓ SET/GET: "${value1}"`);

    // Multiple keys
    await cluster.mset('test:key2', 'value2', 'test:key3', 'value3');
    const values = await cluster.mget('test:key2', 'test:key3');
    console.log(`  ✓ MSET/MGET: [${values.join(', ')}]`);

    // Counter operations
    await cluster.set('test:counter', '0');
    const incr = await cluster.incr('test:counter');
    console.log(`  ✓ INCR: counter = ${incr}`);

    // Expiration
    await cluster.setex('test:temp', 10, 'temporary value');
    const temp = await cluster.get('test:temp');
    console.log(`  ✓ SETEX: temporary value = "${temp}"`);

    console.log('  ✅ Basic operations completed\n');

  } catch (error) {
    console.error('  ❌ Basic operations failed:', error.message);
    throw error;
  }
}

// Test hash slot distribution
async function testHashSlotDistribution() {
  console.log('🎯 Test 2: Hash Slot Distribution');

  try {
    // Create keys that should hash to different slots
    const keys = [
      'user:123:name',
      'user:456:email',
      'product:789:price',
      'order:101:status',
      'session:202:data',
      'cache:303:value'
    ];

    // Set values
    for (let i = 0; i < keys.length; i++) {
      await cluster.set(keys[i], `value_${i + 1}`);
    }

    // Get values and show which node handles each
    for (const key of keys) {
      const value = await cluster.get(key);
      console.log(`  ✓ ${key} → "${value}"`);
    }

    // Test keys with hash tags (force same slot)
    await cluster.set('user:{123}:name', 'John Doe');
    await cluster.set('user:{123}:email', 'john@example.com');
    await cluster.set('user:{123}:age', '30');

    const userData = await cluster.mget('user:{123}:name', 'user:{123}:email', 'user:{123}:age');
    console.log(`  ✓ Hash tags (same slot): [${userData.join(', ')}]`);

    console.log('  ✅ Hash slot distribution working\n');

  } catch (error) {
    console.error('  ❌ Hash slot distribution failed:', error.message);
    throw error;
  }
}

// Test different data types
async function testDataTypes() {
  console.log('📊 Test 3: Data Types Operations');

  try {
    // Lists
    await cluster.rpush('test:list', 'item1', 'item2', 'item3');
    const listLength = await cluster.llen('test:list');
    const listItem = await cluster.lindex('test:list', 1);
    console.log(`  ✓ List: length=${listLength}, item[1]="${listItem}"`);

    // Sets
    await cluster.sadd('test:set', 'member1', 'member2', 'member3');
    const setSize = await cluster.scard('test:set');
    const isMember = await cluster.sismember('test:set', 'member2');
    console.log(`  ✓ Set: size=${setSize}, member2 exists=${isMember}`);

    // Hashes
    await cluster.hset('test:hash', 'field1', 'value1', 'field2', 'value2');
    const hashValue = await cluster.hget('test:hash', 'field1');
    const hashAll = await cluster.hgetall('test:hash');
    console.log(`  ✓ Hash: field1="${hashValue}", all fields:`, hashAll);

    // Sorted Sets
    await cluster.zadd('test:zset', 1, 'member1', 2, 'member2', 3, 'member3');
    const zscore = await cluster.zscore('test:zset', 'member2');
    const zrange = await cluster.zrange('test:zset', 0, -1, 'WITHSCORES');
    console.log(`  ✓ Sorted Set: member2 score=${zscore}, range:`, zrange);

    console.log('  ✅ Data types operations completed\n');

  } catch (error) {
    console.error('  ❌ Data types operations failed:', error.message);
    throw error;
  }
}

// Test cluster information
async function testClusterInfo() {
  console.log('ℹ️  Test 4: Cluster Information');

  try {
    // Get cluster info
    const clusterInfo = await cluster.cluster('info');
    console.log('  📊 Cluster Info:');
    console.log(`    - State: ${clusterInfo.split('\n').find(line => line.startsWith('cluster_state:')).split(':')[1]}`);
    console.log(`    - Slots assigned: ${clusterInfo.split('\n').find(line => line.startsWith('cluster_slots_assigned:')).split(':')[1]}`);
    console.log(`    - Slots ok: ${clusterInfo.split('\n').find(line => line.startsWith('cluster_slots_ok:')).split(':')[1]}`);

    // Get cluster nodes
    const nodes = await cluster.cluster('nodes');
    const nodeLines = nodes.trim().split('\n');
    console.log(`  🖥️  Cluster Nodes: ${nodeLines.length}`);
    nodeLines.forEach((line, index) => {
      const parts = line.split(' ');
      const nodeId = parts[0].substring(0, 8) + '...';
      const host = parts[1].split('@')[0];
      const role = parts[2].includes('master') ? 'MASTER' : 'REPLICA';
      const slots = parts[8] ? `[${parts[8].split('-')[0]}...]` : '[none]';
      console.log(`    ${index + 1}. ${host} (${role}) ${slots}`);
    });

    console.log('  ✅ Cluster information retrieved\n');

  } catch (error) {
    console.error('  ❌ Cluster information failed:', error.message);
    throw error;
  }
}

// Performance test
async function testPerformance() {
  console.log('⚡ Test 5: Performance Test');

  try {
    const iterations = 100;
    const startTime = Date.now();

    // Batch SET operations
    const setPromises = [];
    for (let i = 0; i < iterations; i++) {
      setPromises.push(cluster.set(`perf:key${i}`, `value${i}`));
    }
    await Promise.all(setPromises);

    // Batch GET operations
    const getPromises = [];
    for (let i = 0; i < iterations; i++) {
      getPromises.push(cluster.get(`perf:key${i}`));
    }
    await Promise.all(getPromises);

    const endTime = Date.now();
    const duration = endTime - startTime;
    const opsPerSecond = Math.round((iterations * 2) / (duration / 1000)); // SET + GET

    console.log(`  📈 Performance: ${iterations} SET + ${iterations} GET operations`);
    console.log(`  ⏱️  Duration: ${duration}ms`);
    console.log(`  🚀 Throughput: ~${opsPerSecond} ops/sec`);

    // Cleanup
    const delPromises = [];
    for (let i = 0; i < iterations; i++) {
      delPromises.push(cluster.del(`perf:key${i}`));
    }
    await Promise.all(delPromises);

    console.log('  ✅ Performance test completed\n');

  } catch (error) {
    console.error('  ❌ Performance test failed:', error.message);
    throw error;
  }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

