# Blogger to Jekyll Migration Tool

This tool migrates a Blogger blog to a Jekyll-based static website using Docker. It handles downloading images, organizing posts by year and month, and setting up a modern Jekyll theme.

## Features

- Converts Blogger posts to Jekyll format
- Downloads and localizes all images referenced in posts
- Organizes posts by year and month for easier navigation
- Uses the popular Minimal Mistakes theme for a modern, responsive design
- Runs entirely in Docker for a consistent environment
- Handles HTML to Markdown conversion
- Preserves post metadata and categories

## Requirements

- Docker
- Docker Compose

## Project Structure

The migration process consists of several Python scripts:
- `convert_posts.py`: Converts Blogger XML to Jekyll posts
- `organize_posts.py`: Organizes posts by date
- `html_to_markdown.py`: Converts HTML content to Markdown
- `extract_blog_info.py`: Extracts blog metadata and settings

## Usage

1. Place your Blogger XML export file in the same directory as the `docker-compose.yml` file.
2. Rename your XML file to `sample-blog.xml` (or update the Dockerfile to match your filename).
3. Run the migration:

```bash
docker-compose up
```

4. The migrated Jekyll site will be available in the `migrated-blog-server` directory.

## Running the Jekyll Site Locally

After migration, you can run the Jekyll site locally:

```bash
cd migrated-blog-server
bundle install
bundle exec jekyll serve
```

Then visit http://localhost:4000 in your browser.

## Customization

The migration uses the Minimal Mistakes theme, which is highly customizable. After migration, you can modify the `_config.yml` file in the `migrated-blog-server` directory to customize your site.

## Sample Data

A sample blog XML file (`sample-blog.xml`) is included for testing purposes. You can use this to verify the migration process before using your own blog export.

## Troubleshooting

- If images fail to download, they will remain as external links.
- Check the Docker logs for any errors during migration.
- For theme-specific issues, refer to the [Minimal Mistakes documentation](https://mmistakes.github.io/minimal-mistakes/docs/quick-start-guide/).
- If you encounter any issues with the migration process, check the logs in the `migrated-blog-server` directory.

## License

This migration tool is provided under the MIT License. 