# Hybrid Command Queue System

This document outlines a potential hybrid approach to implementing a command queue system for scooters, combining the strengths of both database and Redis-based solutions.

## Overview

The hybrid approach uses:
1. **Database** for persistent storage of command records and their status
2. **Redis** for the active queue management and fast operations

## Architecture

### Database Component

The database stores all command records with fields for tracking queue status:

- `request_id`: Unique identifier for the command
- `status`: Current status of the command (pending, sent, succeeded, failed, expired)
- `queued`: Boolean flag indicating if the command is in the queue
- `processed_at`: When the command was processed
- `expires_at`: When the command expires
- `queueable`: Whether the command can be queued
- `queue_ttl`: How long the command can remain in the queue

This provides:
- Persistent record of all commands
- Audit trail
- Ability to recover if Redis goes down

### Redis Component

Redis would be used for the actual queue management:

1. **Sorted Sets** for the queue, with score as priority/timestamp and value as command ID
2. **TTL Features** to automatically expire commands
3. **Fast Operations** for queue management

Redis keys would be structured as:
- `scooter:{vin}:command_queue` - Sorted set of command IDs
- `command:{id}:status` - Command status with TTL matching the command's expiration

## Implementation Details

### Queueing a Command

1. Create a record in the database with all command details
2. Add the command ID to the Redis sorted set for the scooter
3. Set the command status in Redis with appropriate TTL

```ruby
def queue_command(command)
  # Database record already created
  
  # Add to Redis queue
  redis.zadd("scooter:#{command.scooter.vin}:command_queue", 
             Time.current.to_i, 
             command.id)
             
  # Set status with TTL
  redis.setex("command:#{command.id}:status", 
              command.queue_ttl, 
              "pending")
end
```

### Processing the Queue

1. Use Redis's `ZRANGEBYSCORE` to efficiently retrieve commands that need processing
2. Process each command and update both Redis and the database
3. Use Redis's TTL to automatically expire commands

```ruby
def process_queue
  # For each scooter with queued commands
  Scooter.joins(:scooter_commands)
         .where(scooter_commands: { queued: true })
         .distinct.each do |scooter|
    
    # Skip if scooter is offline
    next unless scooter.is_online?
    
    # Get command IDs from Redis
    command_ids = redis.zrange("scooter:#{scooter.vin}:command_queue", 0, -1)
    
    command_ids.each do |id|
      # Get command from database
      command = ScooterCommand.find(id)
      
      # Skip if expired
      next if command.expired?
      
      # Process command
      result = process_command(command)
      
      if result.success?
        # Update Redis and database
        redis.zrem("scooter:#{scooter.vin}:command_queue", id)
        redis.del("command:#{id}:status")
        command.mark_as_succeeded
      end
    end
  end
end
```

### Handling Expiration

1. Redis automatically expires command status keys
2. A background job periodically syncs Redis expirations with the database

```ruby
def sync_expired_commands
  # Find commands that should be expired
  ScooterCommand.where(queued: true)
               .where("expires_at <= ?", Time.current)
               .find_each do |command|
    
    # Remove from Redis queue
    redis.zrem("scooter:#{command.scooter.vin}:command_queue", command.id)
    
    # Update database
    command.update(
      queued: false,
      status: "expired",
      processed_at: Time.current
    )
  end
end
```

## Advantages of the Hybrid Approach

1. **Durability**: Database provides persistent storage of command history
2. **Performance**: Redis provides fast queue operations
3. **TTL Support**: Redis has built-in expiration functionality
4. **Recovery**: System can recover if Redis goes down by rebuilding queues from the database
5. **Monitoring**: Database records provide easy monitoring and reporting

## Potential Future Enhancements

1. **Priority Queuing**: Use Redis sorted set scores to prioritize certain commands
2. **Command Batching**: Group commands for more efficient processing
3. **Rate Limiting**: Implement rate limiting per scooter to prevent command flooding
4. **Command Dependencies**: Define dependencies between commands to ensure proper execution order
