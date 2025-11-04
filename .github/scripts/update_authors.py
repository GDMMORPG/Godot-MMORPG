import os
import subprocess
from pathlib import Path
import json
import time
from git import Repo
import requests
import base64

import jwt
import argparse

# --- Configuration ---
AUTHORS_FILE = Path("AUTHORS.md")
ORG = "GDMMORPG"
REPO = "Godot-MMORPG"

ENGINEERING_EXTENSIONS 	= [".gd", ".go", ".cpp", ".h", ".cs", ".rs", ".py", ".sh", ".bat", ".yml", ".yaml", ".sql", ".json", ".xml", ".ini", ".cfg", ".toml"]
ENGINEERING_CRITRIA 	= ["added", "modified", "removed", "renamed"]
ART_EXTENSIONS 			= [".glb", ".gltf", ".fbx", ".png", ".jpg", ".jpeg", ".tga", ".wav", ".mp3", ".ogg", ".psd", ".xcf"]
ART_CRITRIA 			= ["added", "modified", "removed", "renamed"]
DESIGN_EXTENSIONS 		= [".tscn", ".tres"]
DESIGN_CRITRIA 			= ["added", "modified", "removed", "renamed"]
COMMUNITY_EXTENSIONS 	= [".md", ".translation"]
COMMUNITY_CRITRIA 		= ["added", "modified", "removed", "renamed"]


# --- Auth using GitHub App ---
def get_installation_token():
	"""Generate a GitHub App installation token."""

	if "APP_ID" not in os.environ:
		raise EnvironmentError("APP_ID is not set in environment variables.")
	if "INSTALLATION_ID" not in os.environ:
		raise EnvironmentError("INSTALLATION_ID is not set in environment variables.")
	if "PRIVATE_KEY" not in os.environ:
		raise EnvironmentError("PRIVATE_KEY is not set in environment variables.")

	app_id = os.environ["APP_ID"]
	installation_id = os.environ["INSTALLATION_ID"]
	private_key = os.environ["PRIVATE_KEY"].encode()

	payload = {
		"iat": int(time.time()) - 60,
		"exp": int(time.time()) + (10 * 60),
		"iss": app_id,
	}

	jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

	headers = {"Authorization": f"Bearer {jwt_token}", "Accept": "application/vnd.github+json"}
	url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
	res = requests.post(url, headers=headers)
	res.raise_for_status()
	return res.json()["token"]

# --- Helper Functions ---
def detect_category(files_changed: list[str]) -> str:
	"""Determine which category best matches the PR changes."""
	categories = {"Engineering": 0, "Art": 0, "Design": 0, "Community & Support": 0}
	for f in files_changed:
		f_lower: str = f.lower()
		for extension in ENGINEERING_EXTENSIONS:
			if f_lower.endswith(extension):
				categories["Engineering"] += 1
		for extension in ART_EXTENSIONS:
			if f_lower.endswith(extension):
				categories["Art"] += 1
		for extension in DESIGN_EXTENSIONS:
			if f_lower.endswith(extension):
				categories["Design"] += 1
		for extension in COMMUNITY_EXTENSIONS:
			if f_lower.endswith(extension):
				categories["Community & Support"] += 1
	# Return the dominant category
	return max(categories, key=categories.get)

def update_authors_md(pr_number: str, is_dry_run: bool = False):
	"""Insert or update a contributor under the right category in AUTHORS.md."""
	repo = Repo(".")
	token = get_installation_token()
	headers = {
		"Authorization": f"Bearer {token}",
		"Accept": "application/vnd.github+json",
		"X-GitHub-Api-Version": "2022-11-28"
	}

	# Fetch PR details.
	# Todo: Retrieve PR details beyond the pull requester, such as co-authors.
	pr = requests.get(
		f"https://api.github.com/repos/{ORG}/{REPO}/pulls/{pr_number}",
		headers=headers,
	).json()

	username = pr["user"]["login"]

	files = requests.get(
		f"https://api.github.com/repos/{ORG}/{REPO}/pulls/{pr_number}/files",
		headers=headers,
	).json()

	account_details = requests.get(
		f"https://api.github.com/users/{username}",
		headers=headers,
	).json()

	# Aggregate authors and their PRs
	print(f"Processing PR #{pr_number} by user '{pr['user']['login']}'")
	# print(f"Files changed in PR: {[file['filename'] for file in files]}")
	print(f"Number of files changed: {len(files)}")
	# print(f"PR Details: {json.dumps(pr, indent=2)}")
	# print(f"Account Details: {json.dumps(account_details, indent=2)}")
	display_name = account_details.get("name") or username 
	profile_url = pr["user"]["html_url"]
	pr_url = pr["html_url"]
	contribution_categories: dict[str, int] = dict()
	for file in files:
		filename: str = file["filename"].lower()
		status: str = file["status"].lower()

		contribution_categories.setdefault("Engineering", 0)
		contribution_categories.setdefault("Art", 0)
		contribution_categories.setdefault("Design", 0)
		contribution_categories.setdefault("Community & Support", 0)

		if any(filename.endswith(ext) for ext in ENGINEERING_EXTENSIONS) and status in ENGINEERING_CRITRIA:
			contribution_categories["Engineering"] += 1
		if any(filename.endswith(ext) for ext in ART_EXTENSIONS) and status in ART_CRITRIA:
			contribution_categories["Art"] += 1
		if any(filename.endswith(ext) for ext in DESIGN_EXTENSIONS) and status in DESIGN_CRITRIA:
			contribution_categories["Design"] += 1
		if any(filename.endswith(ext) for ext in COMMUNITY_EXTENSIONS) and status in COMMUNITY_CRITRIA:
			contribution_categories["Community & Support"] += 1

	# Determine dominant category
	category = "Community & Support"
	if contribution_categories:
		# Determine the category with the highest contribution count
		category = max(contribution_categories, key=contribution_categories.get)
		# Print out the scores for debugging
		print(f"Contribution scores: {contribution_categories}, selected category: {category}")
	
	# Read and update AUTHORS.md
	content = AUTHORS_FILE.read_text().splitlines()
	contributor_format = f"- [{display_name}]({profile_url})"
	contributor_ref_format = f"PRs: "
	contributor_ref_tag_format = f"[#{pr_number}]({pr_url})"

	# Find category section header
	try:
		start_index = content.index(f"### {category}") + 1
	except ValueError:
		print(f"Category '{category}' not found in AUTHORS.md.")
		return

	# Search if contributor already exists
	existing_idx = None
	for i, line in enumerate(content[start_index:], start=start_index):
		if line.startswith("### "):  # stop at next category
			break
		if contributor_format in line:
			existing_idx = i
			break
	
	did_nothing = False

	if existing_idx:
		# Append new PR tag if not already there
		j = existing_idx + 1
		# Find the end of the contributor's PR tags
		while j < len(content) and content[j].startswith(">"):
			if contributor_ref_tag_format in content[j]:
				# PR tag already exists
				did_nothing = True
				break
			j += 1
		# Insert new PR tag
		if j == len(content) or not content[j].startswith(">"):
			content.insert(j, f"> {contributor_ref_tag_format}")
	else:
		# Insert a new contributor entry
		insert_index = start_index
		while insert_index < len(content) and not content[insert_index].startswith("### "):
			insert_index += 1
		# Insert before the next category or at the end of the section
		# Insert the contributor
		content.insert(insert_index, contributor_format)
		# Insert the PR reference
		content.insert(insert_index + 1, f"> {contributor_ref_format}")
		content.insert(insert_index + 2, f"> {contributor_ref_tag_format}")
		content.insert(insert_index + 3, "")  # Add a blank line for readability

	if did_nothing:
		print(f"ℹ️  No update needed for {username}")
		return

	# Write back to AUTHORS.md
	AUTHORS_FILE.write_text("\n".join(content))
	print(f"✅ Updated AUTHORS.md for {username} in {category}")

	# Commit and push changes.
	repo.index.add([str(AUTHORS_FILE)])
	commit_message = f"Update AUTHORS.md: Add {username} for PR #{pr_number}"
	if repo.is_dirty():
		if not is_dry_run:
			content_base64 = base64.b64encode("\n".join(content).encode("utf-8")).decode("utf-8")
			file_info = requests.get(
				f"https://api.github.com/repos/{ORG}/{REPO}/contents/{AUTHORS_FILE}",
				headers=headers,
			).json()
			sha = file_info["sha"]

			send_edit = requests.put(
				f"https://api.github.com/repos/{ORG}/{REPO}/contents/{AUTHORS_FILE}",
				headers=headers,
				json={
					"message": commit_message, 
					"content": content_base64,
					"sha": sha,
				}
			)

			if send_edit.status_code == 200 or send_edit.status_code == 201:
				print(f"🚀 Pushed changes to AUTHORS.md with commit: {commit_message}")
			else:
				print(f"❌ Failed to push changes: {send_edit.status_code} - {send_edit.json()}")
		else:
			print(f"🧪 Dry run - commit message: {commit_message}")
			print(f"🧪 Dry run mode: Changes not pushed.")
		

def get_merged_pr_info() -> str:
	"""Retrieve merged PR info using GitHub environment variables or git commands."""
	pr_number = os.getenv("PR_NUMBER")

	if not pr_number:
		raise EnvironmentError("PR_NUMBER is not set in environment variables.")

	return pr_number

# --- Main Execution ---
if __name__ == "__main__":
	# Proceed to update AUTHORS.md
	parser = argparse.ArgumentParser(description="Update AUTHORS.md with contributor information")
	parser.add_argument("--dry-run", action="store_true", help="Use dummy information for testing")
	args = parser.parse_args()
	
	if args.dry_run:
		pr_number = "9"
		print("🧪 Running in dry-run mode with dummy data")
	else:
		pr_number = get_merged_pr_info()
	
	update_authors_md(pr_number, is_dry_run=args.dry_run)
