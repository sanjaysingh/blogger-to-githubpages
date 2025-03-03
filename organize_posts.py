#!/usr/bin/env python3
import sys
import os
import re
import shutil
from datetime import datetime

def organize_posts_by_date(posts_dir):
    """Organize Jekyll posts into year/month directories"""
    # First, clean up any existing year/month directories to avoid duplicates
    print("Cleaning up any existing year/month directories...")
    for item in os.listdir(posts_dir):
        item_path = os.path.join(posts_dir, item)
        if os.path.isdir(item_path) and re.match(r'^\d{4}$', item):
            print(f"Removing existing year directory: {item}")
            shutil.rmtree(item_path)
    
    # Get all post files
    post_files = [f for f in os.listdir(posts_dir) if f.endswith('.html') or f.endswith('.md')]
    
    # Create a dictionary to store posts by year and month
    organized_posts = {}
    
    # Regular expression to extract date from filename (YYYY-MM-DD-title.html/md)
    date_pattern = re.compile(r'^(\d{4})-(\d{2})-\d{2}-.*$')
    
    for post_file in post_files:
        match = date_pattern.match(post_file)
        if match:
            year = match.group(1)
            month = match.group(2)
            
            # Create year/month key
            key = f"{year}/{month}"
            
            if key not in organized_posts:
                organized_posts[key] = []
                
            organized_posts[key].append(post_file)
    
    # Create directories and move files
    for key, files in organized_posts.items():
        year, month = key.split('/')
        
        # Create directory structure
        year_dir = os.path.join(posts_dir, year)
        month_dir = os.path.join(year_dir, month)
        
        os.makedirs(month_dir, exist_ok=True)
        
        # Move files to appropriate directory
        for file in files:
            source = os.path.join(posts_dir, file)
            destination = os.path.join(month_dir, file)
            
            # Move the file to the new location (not copy)
            shutil.move(source, destination)
            print(f"Moved {file} to {year}/{month}/")
    
    # Create index files for each year and month
    for key in organized_posts.keys():
        year, month = key.split('/')
        
        # Get month name
        month_name = datetime(int(year), int(month), 1).strftime("%B")
        
        # Create year index if it doesn't exist
        year_index = os.path.join(posts_dir, year, "index.html")
        if not os.path.exists(year_index):
            with open(year_index, 'w', encoding='utf-8') as f:
                f.write(f"""---
layout: archive
title: "Posts from {year}"
permalink: /{year}/
author_profile: false
---

<h2>Archives for {year}</h2>

<ul>
""")
                # Add links to each month
                for m in range(1, 13):
                    m_str = f"{m:02d}"
                    m_dir = os.path.join(posts_dir, year, m_str)
                    if os.path.exists(m_dir):
                        m_name = datetime(int(year), m, 1).strftime("%B")
                        f.write(f'  <li><a href="/{year}/{m_str}/">{m_name}</a></li>\n')
                f.write("</ul>\n")
        
        # Create month index
        month_index = os.path.join(posts_dir, year, month, "index.html")
        with open(month_index, 'w', encoding='utf-8') as f:
            f.write(f"""---
layout: archive
title: "Posts from {month_name} {year}"
permalink: /{year}/{month}/
author_profile: false
---

<h2>Archives for {month_name} {year}</h2>

<ul>
""")
            # Add links to each post
            for post_file in organized_posts[key]:
                # Extract title from filename
                file_ext = os.path.splitext(post_file)[1]  # Get the file extension
                title = post_file[11:-len(file_ext)].replace('-', ' ').title()
                slug = post_file[11:-len(file_ext)]
                # Extract date from filename (YYYY-MM-DD)
                post_date = post_file[0:10]
                f.write(f'  <li><a href="/{year}/{month}/{post_date}/{slug}/">{title}</a></li>\n')
            f.write("</ul>\n")
    
    # Create a data file for the archive navigation
    data_dir = os.path.join(os.path.dirname(posts_dir), "_data")
    os.makedirs(data_dir, exist_ok=True)
    
    # Create a navigation data file for the archive sidebar
    with open(os.path.join(data_dir, "navigation.yml"), 'w', encoding='utf-8') as f:
        f.write("""# Main navigation links
main:
  - title: "Home"
    url: /
  - title: "Archives"
    url: /archives/
""")
    
    # Create an archives page
    pages_dir = os.path.join(os.path.dirname(posts_dir), "_pages")
    os.makedirs(pages_dir, exist_ok=True)
    
    with open(os.path.join(pages_dir, "archives.md"), 'w', encoding='utf-8') as f:
        f.write("""---
title: "Archives"
layout: archive
permalink: /archives/
author_profile: false
---

{% assign posts_by_year = site.posts | group_by_exp:"post", "post.date | date: '%Y'" %}
{% for year in posts_by_year %}
  <h2 id="{{ year.name }}">{{ year.name }}</h2>
  {% assign posts_by_month = year.items | group_by_exp:"post", "post.date | date: '%m'" %}
  {% for month in posts_by_month %}
    {% assign month_name = month.items[0].date | date: '%B' %}
    <h3 id="{{ year.name }}-{{ month.name }}">{{ month_name }}</h3>
    <ul>
      {% for post in month.items %}
        <li>
          <a href="{{ post.url }}">{{ post.title }}</a>
          <small>{{ post.date | format_date }}</small>
        </li>
      {% endfor %}
    </ul>
  {% endfor %}
{% endfor %}
""")
    
    # Final cleanup - check for any remaining post files in the root directory
    remaining_files = [f for f in os.listdir(posts_dir) if os.path.isfile(os.path.join(posts_dir, f)) and (f.endswith('.html') or f.endswith('.md'))]
    if remaining_files:
        print(f"Removing {len(remaining_files)} remaining post files from root directory...")
        for file in remaining_files:
            os.remove(os.path.join(posts_dir, file))
            print(f"Removed {file} from root directory")
    
    print("Posts organized by year and month successfully!")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python organize_posts.py <posts_dir>")
        sys.exit(1)
    
    posts_dir = sys.argv[1]
    organize_posts_by_date(posts_dir) 