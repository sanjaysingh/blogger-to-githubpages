# Blogger to Jekyll Migration Tool

A Docker-based tool that migrates Blogger blogs to Jekyll static websites, handling image downloads, post organization, and modern theming.

## Features

- Converts Blogger posts to Jekyll format
- Downloads and localizes all images
- Organizes posts by year and month
- Uses Minimal Mistakes theme
- Docker-based for consistent execution

## Quick Start

1. Place your Blogger XML export file in the project root
2. Run the migration:
```bash
docker-compose up
```
3. The migrated site will be in the `migrated-blog-server` directory

## Local Development

To run the Jekyll site locally:
```bash
cd migrated-blog-server
bundle install
bundle exec jekyll serve
```
Visit http://localhost:4000 to view your site.

## Customization

Modify `_config.yml` in `migrated-blog-server` to customize your site's settings and appearance.

## Requirements

- Docker
- Docker Compose

## License

MIT License 