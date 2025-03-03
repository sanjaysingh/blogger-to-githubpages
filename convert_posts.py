#!/usr/bin/env python3
import sys
import os
import re
import xml.etree.ElementTree as ET
from datetime import datetime
import urllib.request
import urllib.parse
import hashlib
import html
import time

def download_image(url, image_dir, post_id, post_title, image_counter):
    """Download an image and return the local path"""
    try:
        # Create a sanitized filename from post title
        safe_title = re.sub(r'[^a-zA-Z0-9]+', '-', post_title.lower()).strip('-')
        
        # Extract file extension from URL
        parsed_url = urllib.parse.urlparse(url)
        path = parsed_url.path
        ext = os.path.splitext(path)[1]
        
        # If no extension or unusual extension, default to .jpg
        if not ext or len(ext) > 5:
            ext = '.jpg'
            
        # Create filename with post title and counter for multiple images
        filename = f"{safe_title}-{image_counter}{ext}"
        local_path = os.path.join(image_dir, filename)
        
        # Skip if already downloaded
        if os.path.exists(local_path):
            return f"/assets/images/{filename}"
            
        # Download the image
        print(f"Downloading image: {url}")
        
        # Add a user agent to avoid 403 errors
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        req = urllib.request.Request(url, headers=headers)
        
        with urllib.request.urlopen(req, timeout=30) as response, open(local_path, 'wb') as out_file:
            out_file.write(response.read())
            
        # Add a small delay to avoid rate limiting
        time.sleep(0.5)
        
        return f"/assets/images/{filename}"
    except Exception as e:
        print(f"Error downloading image {url}: {e}")
        return url  # Return original URL if download fails

def process_content(content, image_dir, post_id, post_title):
    """Process post content to download images and fix formatting"""
    # Replace Blogger image references with local paths
    img_pattern = re.compile(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*>')
    
    # Counter for images in this post
    image_counter = 1
    
    def replace_image(match):
        nonlocal image_counter
        img_tag = match.group(0)
        img_url = match.group(1)
        
        # Skip data URLs
        if img_url.startswith('data:'):
            return img_tag
            
        # Download the image and get local path
        local_path = download_image(img_url, image_dir, post_id, post_title, image_counter)
        
        # Increment counter for next image
        image_counter += 1
        
        # Replace the URL in the img tag
        return img_tag.replace(img_url, local_path)
    
    # Replace image URLs
    content = img_pattern.sub(replace_image, content)
    
    # Fix common HTML issues
    content = content.replace('<br>', '<br />')
    
    # Enhance code blocks with syntax highlighting
    def enhance_code_blocks(match):
        pre_tag = match.group(0)
        code_content = match.group(1)
        
        # Try to detect language from content
        lang = ""
        # Check for common language patterns
        if re.search(r'(function|var|let|const|=>)\s', code_content):
            lang = "javascript"
        elif re.search(r'(def|class|import|from|if __name__)', code_content):
            lang = "python"
        elif re.search(r'(public|private|class|void|String)\s', code_content):
            lang = "java"
        elif re.search(r'(<html|<div|<span|<p>|<a\s)', code_content):
            lang = "html"
        elif re.search(r'(#include|int\s+main|printf|scanf)', code_content):
            lang = "c"
        elif re.search(r'(namespace|using\s+std|template|cout)', code_content):
            lang = "cpp"
        elif re.search(r'(\$|function|echo|<?php)', code_content):
            lang = "php"
        elif re.search(r'(SELECT|FROM|WHERE|INSERT|UPDATE|DELETE)', code_content, re.IGNORECASE):
            lang = "sql"
        
        # Add language class if detected
        if lang:
            if '<code' in pre_tag:
                pre_tag = pre_tag.replace('<code', f'<code class="language-{lang}"', 1)
            else:
                pre_tag = pre_tag.replace('<pre', f'<pre class="language-{lang}"', 1)
        
        return pre_tag
    
    # Find and enhance code blocks
    content = re.sub(r'<pre[^>]*>(.*?)</pre>', enhance_code_blocks, content, flags=re.DOTALL)
    
    # Remove inline styles to ensure consistent font styling
    content = re.sub(r'style=["\'][^"\']*["\']', '', content)
    
    # Remove font tags
    content = re.sub(r'<font[^>]*>(.*?)</font>', r'\1', content)
    
    # Remove span tags with styling
    content = re.sub(r'<span[^>]*>(.*?)</span>', r'\1', content)
    
    # Remove div tags with styling but keep content
    content = re.sub(r'<div[^>]*>(.*?)</div>', r'\1', content)
    
    return content

def add_excerpt_separator(content):
    """No longer adding excerpt separators as we're showing full content"""
    # We're no longer adding excerpt separators
    return content

def convert_blogger_to_jekyll(xml_file, posts_dir, image_dir):
    """Convert Blogger XML export to Jekyll posts"""
    # Create directories if they don't exist
    os.makedirs(posts_dir, exist_ok=True)
    os.makedirs(image_dir, exist_ok=True)
    
    # Parse the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    # Define namespaces
    namespaces = {
        '': 'http://www.w3.org/2005/Atom',
        'app': 'http://purl.org/atom/app#',
    }
    
    # Find all entries that are posts (not pages or comments)
    entries = root.findall('entry', namespaces)
    post_count = 0
    
    for entry in entries:
        # Skip non-posts (like comments, templates, etc.)
        kind = None
        is_post = False
        
        # Check if this is a post by looking at categories
        categories = entry.findall('category', namespaces)
        for category in categories:
            term = category.get('term', '')
            if 'kind#post' in term:
                kind = 'post'
                is_post = True
                break
        
        # Skip if not a post
        if not is_post:
            continue
            
        # Skip if it's a comment (has thr:in-reply-to element)
        reply_to = entry.find('{http://purl.org/syndication/thread/1.0}in-reply-to')
        if reply_to is not None:
            continue
            
        # Extract post ID
        id_elem = entry.find('id', namespaces)
        post_id = id_elem.text.split('-')[-1] if id_elem is not None else f"post-{post_count}"
        
        # Extract post title
        title_elem = entry.find('title', namespaces)
        title = title_elem.text if title_elem is not None and title_elem.text is not None else f"Untitled-{post_id}"
        
        # Skip posts with titles that look like they're from the theme
        if title.startswith("Layout:") or title.startswith("Post:") or title.startswith("Markup:"):
            continue
            
        # Skip untitled posts
        if title.startswith("Untitled-"):
            continue
        
        # Clean title for YAML
        title = title.replace('"', '\\"').replace(":", "&#58;")
        
        # Extract published date
        published_elem = entry.find('published', namespaces)
        if published_elem is not None:
            published_date = published_elem.text
            # Convert to Jekyll date format (YYYY-MM-DD)
            try:
                dt = datetime.strptime(published_date, "%Y-%m-%dT%H:%M:%S.%f%z")
            except ValueError:
                try:
                    dt = datetime.strptime(published_date, "%Y-%m-%dT%H:%M:%S%z")
                except ValueError:
                    dt = datetime.now()
            
            # Use UTC date for filename to avoid timezone issues
            date_str = dt.strftime("%Y-%m-%d")
            
            # For the front matter, explicitly set the timezone to UTC
            # This ensures Jekyll displays the same date as the filename
            time_str = dt.strftime("%H:%M:%S +0000")
        else:
            date_str = datetime.now().strftime("%Y-%m-%d")
            time_str = datetime.now().strftime("%H:%M:%S +0000")
        
        # Extract content
        content_elem = entry.find('content', namespaces)
        if content_elem is not None:
            content = content_elem.text or ""
        else:
            content = ""
            
        # Skip if content is empty or too short (likely not a real post)
        if not content or len(content.strip()) < 10:
            continue
            
        # Unescape HTML entities in content
        content = html.unescape(content)
        
        # Process content (download images, fix formatting, remove inline styles)
        content = process_content(content, image_dir, post_id, title)
        
        # We no longer add excerpt separators as we're showing full content
        # content = add_excerpt_separator(content)
        
        # Extract tags/labels
        tags = []
        categories = entry.findall('category', namespaces)
        for category in categories:
            term = category.get('term', '')
            scheme = category.get('scheme', '')
            if 'kind#post' not in term and 'kind#' not in term and term:
                tags.append(term)
        
        # Create slug from title
        slug = re.sub(r'[^a-zA-Z0-9]+', '-', title.lower()).strip('-')
        
        # Create Jekyll front matter - remove the blog category
        front_matter = f"""---
title: "{title}"
date: {date_str} {time_str}
tags:
{chr(10).join(['  - ' + tag for tag in tags]) if tags else '  - uncategorized'}
---

"""
        
        # Create Jekyll post filename
        filename = f"{date_str}-{slug}.md"
        post_path = os.path.join(posts_dir, filename)
        
        # Write Jekyll post
        with open(post_path, 'w', encoding='utf-8') as f:
            f.write(front_matter + content)
            
        post_count += 1
        print(f"Converted post: {title}")
    
    print(f"Converted {post_count} posts to Jekyll format")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python convert_posts.py <blogger_xml_file> <posts_dir> <image_dir>")
        sys.exit(1)
    
    xml_file = sys.argv[1]
    posts_dir = sys.argv[2]
    image_dir = sys.argv[3]
    
    convert_blogger_to_jekyll(xml_file, posts_dir, image_dir) 