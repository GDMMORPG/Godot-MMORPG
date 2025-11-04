-- Migration 000002_characters.up.sql
-- Description: Create characters table to store character information linked to users.

-- Create characters table
-- Stores character information associated with users.
CREATE TABLE characters (
	id SERIAL PRIMARY KEY,
	user_id INT NOT NULL,
	character_name VARCHAR(100) NOT NULL,
	level INT DEFAULT 1,
	class VARCHAR(50),
	race VARCHAR(50),
	world_index INT,
	world_position TEXT,
	status VARCHAR(50) DEFAULT 'ALIVE',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deletion_date TIMESTAMP,
	FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_characters_user_id ON characters(user_id);

-- Create index on character_name for faster searches
CREATE INDEX idx_characters_character_name ON characters(character_name);

-- Add a unique constraint to ensure a user cannot have duplicate character names
ALTER TABLE characters
ADD CONSTRAINT unique_user_character_name UNIQUE (user_id, character_name);

-- Add a foreign key constraint to ensure referential integrity with users table
ALTER TABLE characters
ADD CONSTRAINT fk_characters_user_id FOREIGN KEY (user_id) REFERENCES users(id);


-- Character Inventory Table
-- Stores inventory items for each character.
CREATE TABLE character_inventories (
	id SERIAL PRIMARY KEY,
	character_id INT NOT NULL,
	item_id INT NOT NULL,
	quantity INT DEFAULT 1,
	grid_data TEXT,
	metadata TEXT,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (character_id) REFERENCES characters(id)
);

-- Create index on character_id for faster lookups
CREATE INDEX idx_character_inventories_character_id ON character_inventories(character_id);
-- Create index on item_id for faster searches
CREATE INDEX idx_character_inventories_item_id ON character_inventories(item_id);
-- Add a foreign key constraint to ensure referential integrity with characters table
ALTER TABLE character_inventories
ADD CONSTRAINT fk_character_inventories_character_id FOREIGN KEY (character_id) REFERENCES characters(id);