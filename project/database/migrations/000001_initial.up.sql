-- Migration 000001_initial.up.sql
-- Description: Initial database schema setup

-- Create users table
-- Stores basic user information, treat this as a profile table.
CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	displayname VARCHAR(50) NOT NULL UNIQUE,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create authentication_method_discords table
-- Stores Discord authentication details linked to user_authentications, this allows for a user to login via Discord.
CREATE TABLE authentication_method_discords (
	id SERIAL PRIMARY KEY,
	user_id INT NOT NULL,
	discord_id VARCHAR(100) NOT NULL UNIQUE,
	username VARCHAR(100) NOT NULL,
	discriminator VARCHAR(10) NOT NULL,
	avatar_url VARCHAR(255),
	email VARCHAR(100),
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create user_authenticated_sessions table
-- Stores active authenticated sessions for users, this would be front-loaded with a caching service to allow for quick session validation.
CREATE TABLE user_authenticated_sessions (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	user_id INT NOT NULL,
	authentication_method VARCHAR(50) NOT NULL,
	authentication_method_id INT NOT NULL,  -- No foreign key constraint to allow flexibility
	last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	expires_at TIMESTAMP NOT NULL,
	FOREIGN KEY (user_id) REFERENCES users(id),
	UNIQUE (user_id, authentication_method)
);

-- Create index on displayname for faster lookups
CREATE INDEX idx_users_displayname ON users(displayname);