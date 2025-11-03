import os
import subprocess
from pathlib import Path

AUTHORS_FILE = Path("AUTHORS.md")

ENGINEERING_EXTENSIONS = [".gd", ".go", ".cpp", ".h", ".cs", ".py", ".sh", ".yml", ".yaml", ".json", ".xml", ".ini", ".cfg", ".toml"]
ART_EXTENSIONS = [".glb", ".gltf", ".fbx", ".png", ".jpg", ".jpeg", ".tga", ".wav", ".mp3", ".ogg", ".psd", ".xcf"]
DESIGN_EXTENSIONS = [".tscn", ".tres", ".cfg", ".ini", ".json", ".xml"]
COMMUNITY_EXTENSIONS = []

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

def update_authors_md(username: str, profile_url: str, pr_number: str, category: str):
	"""Insert or update a contributor under the right category in AUTHORS.md."""
	content = AUTHORS_FILE.read_text().splitlines()
	new_line = f"- [{username}]({profile_url})"
	pr_tag = f"# {pr_number}"

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
		if username in line:
			existing_idx = i
			break

	if existing_idx:
		# Append new PR tag if not already there
		j = existing_idx + 1
		while j < len(content) and content[j].startswith(">"):
			if pr_tag in content[j]:
				break
			j += 1
		if j == len(content) or not content[j].startswith(">"):
			content.insert(j, f"> {pr_tag}")
	else:
		# Insert a new contributor entry
		insert_index = start_index
		while insert_index < len(content) and not content[insert_index].startswith("### "):
			insert_index += 1
		content.insert(insert_index, f"- [{username}]({profile_url})")
		content.insert(insert_index + 1, f"> {pr_tag}")

	AUTHORS_FILE.write_text("\n".join(content))
	print(f"✅ Updated AUTHORS.md for {username} in {category}")

def get_merged_pr_info() -> tuple[str, str, str, str]:
	"""Retrieve merged PR info using GitHub environment variables or git commands."""
	pr_number = os.getenv("PR_NUMBER")
	username = os.getenv("PR_USER")
	profile_url = f"https://github.com/{username}"

	# Get list of changed files
	diff_cmd = ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"]
	files_changed = subprocess.check_output(diff_cmd).decode().splitlines()
	category = detect_category(files_changed)

	return username, profile_url, pr_number, category

if __name__ == "__main__":
	username, profile_url, pr_number, category = get_merged_pr_info()
	update_authors_md(username, profile_url, pr_number, category)
